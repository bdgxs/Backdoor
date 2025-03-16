import UIKit

class SigningsDylibViewController: UITableViewController {
    var applicationPath: URL
    var groupedDylibs: [String: [String]] = [:]
    var dylibSections: [String] = ["@rpath", "@executable_path", "/usr/lib", "/System/Library", "Other"]
    var dylibstoremove: [String] = [] {
        didSet {
            self.mainOptions.mainOptions.removeInjectPaths = self.dylibstoremove
        }
    }

    var mainOptions: SigningMainDataWrapper

    init(mainOptions: SigningMainDataWrapper, app: URL) {
        self.mainOptions = mainOptions
        self.applicationPath = app
        super.init(style: .insetGrouped)

        do {
            if let executable = try TweakHandler.findExecutable(at: applicationPath) {
                if let dylibs = try listDylibs(filePath: executable.path) {
                    groupDylibs(dylibs)
                } else {
                    print("Failed to list dylibs")
                }
            } else {
                print("Failed to find executable")
            }
        } catch {
            print("Error finding executable: \(error)")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNavigation()
        self.dylibstoremove = self.mainOptions.mainOptions.removeInjectPaths
    }

    fileprivate func setupViews() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "dylibCell")

        let alertController = UIAlertController(title: "ADVANCED USERS ONLY", message: "This section can make installed applications UNUSABLE and potentially UNSTABLE. USE THIS SECTION WITH CAUTION.", preferredStyle: .alert)

        let continueAction = UIAlertAction(title: "WHO CARES", style: .destructive, handler: nil)

        alertController.addAction(continueAction)

        present(alertController, animated: true, completion: nil)
    }

    fileprivate func setupNavigation() {
        title = "Remove Dylibs"
    }

    fileprivate func groupDylibs(_ dylibs: [String]) {
        groupedDylibs["@rpath"] = dylibs.filter { $0.hasPrefix("@rpath") }.sorted()
        groupedDylibs["@executable_path"] = dylibs.filter { $0.hasPrefix("@executable_path") }.sorted()
        groupedDylibs["/usr/lib"] = dylibs.filter { $0.hasPrefix("/usr/lib") }.sorted()
        groupedDylibs["/System/Library"] = dylibs.filter { $0.hasPrefix("/System/Library") }.sorted()
        groupedDylibs["Other"] = dylibs.filter { dylib in
            !dylib.hasPrefix("@rpath") &&
            !dylib.hasPrefix("@executable_path") &&
            !dylib.hasPrefix("/usr/lib") &&
            !dylib.hasPrefix("/System/Library")
        }.sorted()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dylibSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = dylibSections[section]
        return groupedDylibs[key]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dylibSections[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dylibCell", for: indexPath)
        let key = dylibSections[indexPath.section]
        if let dylib = groupedDylibs[key]?[indexPath.row] {
            cell.textLabel?.text = dylib
            cell.textLabel?.textColor = dylibstoremove.contains(dylib) ? .systemRed : .label
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = dylibSections[indexPath.section]
        if let dylib = groupedDylibs[key]?[indexPath.row] {
            if dylibstoremove.contains(dylib) {
                if let index = dylibstoremove.firstIndex(of: dylib) {
                    dylibstoremove.remove(at: index)
                }
            } else {
                dylibstoremove.append(dylib)
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            print(dylibstoremove)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // Add the missing functions here
    func listDylibs(filePath: String) throws -> [String]? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        task.arguments = ["-L", filePath]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Capture standard error too

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                var dylibs: [String] = []

                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.hasPrefix("\t") {
                        if let dylib = trimmedLine.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) {
                            dylibs.append(dylib)
                        }
                    }
                }
                return dylibs
            }
        } else {
            let errorData = task.standardError as! Pipe
            let errorString = String(data: errorData.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
            print("otool error: \(errorString ?? "Unknown error")")
            throw NSError(domain: "otool", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "otool failed with status \(task.terminationStatus)"])
        }
        return nil
    }
}
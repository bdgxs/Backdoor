import UIKit
import ZIPFoundation

class IPAEditorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let fileURL: URL
    private let tableView: UITableView
    private var contents: [URL] = []
    private let fileManager = FileManager.default
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        self.tableView = UITableView()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractIPAContents()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        view.layer.applyFuturisticShadow()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.layer.cornerRadius = 10
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        tableView.isAccessibilityElement = true
        tableView.accessibilityLabel = "IPA Contents"
    }
    
    private func extractIPAContents() {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.unzipItem(at: fileURL, to: tempDirectory)
            contents = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            presentAlert(title: "Error", message: "Failed to extract IPA: \(error.localizedDescription)")
        }
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = contents[indexPath.row].lastPathComponent
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedURL = contents[indexPath.row]
        if selectedURL.pathExtension.lowercased() == "plist" {
            let editor = PlistEditorViewController(fileURL: selectedURL)
            navigationController?.pushViewController(editor, animated: true)
        } else {
            presentAlert(title: "Unsupported", message: "Only .plist files can be edited within IPA.")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
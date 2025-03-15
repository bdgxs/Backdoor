import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerViewControllerDelegate {
    
    // MARK: - Properties
    private var ipaPath: String = ""
    private var fileList: [String] = []
    private let fileManager = FileManager.default

    // MARK: - UI Elements
    private let selectIPAButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select IPA", for: .normal)
        button.addTarget(self, action: #selector(selectIPAButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let listFilesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("List Files", for: .normal)
        button.addTarget(self, action: #selector(listFilesButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let fileListTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white

        // Add UI elements to the view
        view.addSubview(selectIPAButton)
        view.addSubview(listFilesButton)
        view.addSubview(fileListTableView)

        // Set up constraints
        NSLayoutConstraint.activate([
            selectIPAButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            selectIPAButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            listFilesButton.topAnchor.constraint(equalTo: selectIPAButton.bottomAnchor, constant: 20),
            listFilesButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            fileListTableView.topAnchor.constraint(equalTo: listFilesButton.bottomAnchor, constant: 20),
            fileListTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            fileListTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            fileListTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        // Register the table view cell
        fileListTableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
    }

    // MARK: - Actions
    @objc private func selectIPAButtonTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }

    @objc private func listFilesButtonTapped() {
        listFiles()
    }

    // MARK: - ZIP Handling
    private func listFiles() {
        guard !ipaPath.isEmpty else {
            print("Please select an IPA file first.")
            return
        }

        do {
            let zipFilePath = URL(fileURLWithPath: ipaPath)
            let destinationURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("extracted")

            // Check if destination directory exists, create if necessary
            if !fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            }

            let archive = try Archive(url: zipFilePath, accessMode: .read)

            for entry in archive {
                var destination = destinationURL.appendingPathComponent(entry.path)
                if entry.type == .directory {
                    try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
                } else {
                    try archive.extract(entry, to: destination)
                }
                print("Extracted \(entry.path)")
            }

            // List files after extraction
            let contents = try fileManager.contentsOfDirectory(atPath: destinationURL.path)
            fileList = contents
            fileListTableView.reloadData() // Reload the table view to display the files

        } catch {
            print("Extraction failed with error: \(error)")
        }
    }

    // MARK: - UIDocumentPickerViewControllerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        ipaPath = selectedFileURL.path
        print("Selected IPA: \(ipaPath)")
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = fileList[indexPath.row]
        return cell
    }
}
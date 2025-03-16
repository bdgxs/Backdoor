import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate {
    
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

    // Additional buttons for file operations
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share File", for: .normal)
        button.addTarget(self, action: #selector(shareFile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy File", for: .normal)
        button.addTarget(self, action: #selector(copyFile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let moveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Move File", for: .normal)
        button.addTarget(self, action: #selector(moveFile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let compressButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Compress File", for: .normal)
        button.addTarget(self, action: #selector(compressFile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let renameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Rename File", for: .normal)
        button.addTarget(self, action: #selector(renameFile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete File", for: .normal)
        button.addTarget(self, action: #selector(deleteFile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        view.addSubview(shareButton)
        view.addSubview(copyButton)
        view.addSubview(moveButton)
        view.addSubview(compressButton)
        view.addSubview(renameButton)
        view.addSubview(deleteButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            selectIPAButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            selectIPAButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            listFilesButton.topAnchor.constraint(equalTo: selectIPAButton.bottomAnchor, constant: 20),
            listFilesButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            shareButton.topAnchor.constraint(equalTo: listFilesButton.bottomAnchor, constant: 20),
            shareButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            copyButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 20),
            copyButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            moveButton.topAnchor.constraint(equalTo: copyButton.bottomAnchor, constant: 20),
            moveButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            compressButton.topAnchor.constraint(equalTo: moveButton.bottomAnchor, constant: 20),
            compressButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            renameButton.topAnchor.constraint(equalTo: compressButton.bottomAnchor, constant: 20),
            renameButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            deleteButton.topAnchor.constraint(equalTo: renameButton.bottomAnchor, constant: 20),
            deleteButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            fileListTableView.topAnchor.constraint(equalTo: deleteButton.bottomAnchor, constant: 20),
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

    @objc private func shareFile() {
        guard !ipaPath.isEmpty else {
            print("Please select a file first.")
            return
        }
        let fileURL = URL(fileURLWithPath: ipaPath)
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }

    @objc private func copyFile() {
        guard !ipaPath.isEmpty else {
            print("Please select a file first.")
            return
        }
        let fileURL = URL(fileURLWithPath: ipaPath)
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("Copy_\(fileURL.lastPathComponent)")
        do {
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            print("File copied to \(destinationURL.path)")
        } catch {
            print("Copy failed with error: \(error)")
        }
    }

    @objc private func moveFile() {
        guard !ipaPath.isEmpty else {
            print("Please select a file first.")
            return
        }
        let fileURL = URL(fileURLWithPath: ipaPath)
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("Moved_\(fileURL.lastPathComponent)")
        do {
            try fileManager.moveItem(at: fileURL, to: destinationURL)
            print("File moved to \(destinationURL.path)")
        } catch {
            print("Move failed with error: \(error)")
        }
    }

    @objc private func compressFile() {
        guard !ipaPath.isEmpty else {
            print("Please select a file first.")
            return
        }
        let fileURL = URL(fileURLWithPath: ipaPath)
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("\(fileURL.lastPathComponent).zip")
        do {
            let archive = try Archive(url: destinationURL, accessMode: .create)
            try archive.addEntry(with: fileURL.lastPathComponent, relativeTo: fileURL.deletingLastPathComponent())
            print("File compressed to \(destinationURL.path)")
        } catch {
            print("Compression failed with error: \(error)")
        }
    }

    @objc private func renameFile() {
        guard !ipaPath.isEmpty else {
            print("Please select a file first.")
            return
        }
        let fileURL = URL(fileURLWithPath: ipaPath)
        let alertController = UIAlertController(title: "Rename File", message: "Enter new file name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = fileURL.lastPathComponent
        }
        let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
            guard let newName = alertController.textFields?.first?.text else { return }
            let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
            do {
                try self.fileManager.moveItem(at: fileURL, to: destinationURL)
                print("File renamed to \(destinationURL.path)")
            } catch {
                print("Rename failed with error: \(error)")
            }
        }
        alertController.addAction(renameAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    @objc private func deleteFile() {
        guard !ipaPath.isEmpty else {
            print("Please select a file first.")
            return
        }
        let fileURL = URL(fileURLWithPath: ipaPath)
        do {
            try fileManager.removeItem(at: fileURL)
            print("File deleted")
        } catch {
            print("Delete failed with error: \(error)")
        }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = fileList[indexPath.row]
        let fileURL = URL(fileURLWithPath: ipaPath).appendingPathComponent(fileName)
        openFile(fileURL)
    }

    private func openFile(_ fileURL: URL) {
        let fileExtension = fileURL.pathExtension.lowercased()

        switch fileExtension {
        case "txt":
            openTextEditor(fileURL)
        case "plist":
            openPlistEditor(fileURL)
        default:
            openHexEditor(fileURL)
        }
    }

    private func openTextEditor(_ fileURL: URL) {
        let textEditorVC = TextEditorViewController(fileURL: fileURL)
        navigationController?.pushViewController(textEditorVC, animated: true)
    }

    private func openPlistEditor(_ fileURL: URL) {
        let plistEditorVC = PlistEditorViewController(fileURL: fileURL)
        navigationController?.pushViewController(plistEditorVC, animated: true)
    }

    private func openHexEditor(_ fileURL: URL) {
        let hexEditorVC = HexEditorViewController(fileURL: fileURL)
        navigationController?.pushViewController(hexEditorVC, animated: true)
    }
}
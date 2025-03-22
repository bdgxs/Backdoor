import UIKit

class HexEditorViewController: UIViewController, UITextViewDelegate {
    private let fileURL: URL
    private var textView: UITextView!
    private var toolbar: UIToolbar!
    private var hasUnsavedChanges = false
    private var autoSaveTimer: Timer?

    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFileContent()
        startAutoSaveTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if hasUnsavedChanges {
            promptSaveChanges()
        } else {
            navigationController?.popViewController(animated: true)
        }
        stopAutoSaveTimer()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Setup text view
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.delegate = self
        view.addSubview(textView)

        // Setup toolbar
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveChanges))
        let copyButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(copyContent))
        let findReplaceButton = UIBarButtonItem(title: "Find/Replace", style: .plain, target: self, action: #selector(promptFindReplace))
        let undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undoAction))
        let redoButton = UIBarButtonItem(barButtonSystemItem: .redo, target: self, action: #selector(redoAction))
        toolbar.items = [saveButton, copyButton, findReplaceButton, undoButton, redoButton, UIBarButtonItem.flexibleSpace()]
        view.addSubview(toolbar)

        // Setup constraints
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadFileContent() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try Data(contentsOf: self.fileURL)
                let hexString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
                DispatchQueue.main.async {
                    self.textView.text = hexString
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Failed to load file content: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func saveChanges() {
        guard let text = textView.text else {
            return
        }
        let hexValues = text.components(separatedBy: " ").compactMap { UInt8($0, radix: 16) }
        let data = Data(hexValues)
        do {
            try data.write(to: fileURL)
            hasUnsavedChanges = false
            print("File saved successfully.")
        } catch {
            print("Error saving file: \(error)")
            presentAlert(title: "Error", message: "Could not save file.")
        }
    }

    @objc private func copyContent() {
        UIPasteboard.general.string = textView.text
        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
        print("Content copied to clipboard.")
    }

    @objc private func promptFindReplace() {
        let alert = UIAlertController(title: "Find and Replace", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Find"
        }
        alert.addTextField { textField in
            textField.placeholder = "Replace"
        }
        alert.addAction(UIAlertAction(title: "Replace", style: .default, handler: { [weak self] _ in
            guard let findText = alert.textFields?[0].text,
                  let replaceText = alert.textFields?[1].text else {
                return
            }
            if let currentText = self?.textView.text {
                self?.textView.text = currentText.replacingOccurrences(of: findText, with: replaceText)
                self?.hasUnsavedChanges = true
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc private func undoAction() {
        textView.undoManager?.undo()
    }

    @objc private func redoAction() {
        textView.undoManager?.redo()
    }

    func textViewDidChange(_ textView: UITextView) {
        hasUnsavedChanges = true
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

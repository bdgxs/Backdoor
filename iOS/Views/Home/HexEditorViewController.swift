import UIKit

class HexEditorViewController: UIViewController, UITextViewDelegate {
    let fileURL: URL
    let textView: UITextView
    let toolbar: UIToolbar
    var hasUnsavedChanges = false
    var autoSaveTimer: Timer?

    init(fileURL: URL) {
        self.fileURL = fileURL
        self.textView = UITextView()
        self.toolbar = UIToolbar()
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
        stopAutoSaveTimer()
        if hasUnsavedChanges {
            promptSaveChanges()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    func setupUI() {
        view.backgroundColor = .systemBackground

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.delegate = self
        view.addSubview(textView)

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveChanges))
        let copyButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(copyContent))
        let findReplaceButton = UIBarButtonItem(title: "Find/Replace", style: .plain, target: self, action: #selector(promptFindReplace))
        let undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undoAction))
        let redoButton = UIBarButtonItem(barButtonSystemItem: .redo, target: self, action: #selector(redoAction))
        toolbar.items = [saveButton, copyButton, findReplaceButton, undoButton, redoButton, UIBarButtonItem.flexibleSpace()]
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        textView.isAccessibilityElement = true
        textView.accessibilityLabel = "Hex Editor"
        toolbar.isAccessibilityElement = true
        toolbar.accessibilityLabel = "Toolbar"
    }

    func loadFileContent() {
        DispatchQueue.global(qos: .userInitiated).async {
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

    @objc func saveChanges() {
        guard let text = textView.text else { return }
        let hexValues = text.components(separatedBy: " ").compactMap { UInt8($0, radix: 16) }
        let data = Data(hexValues)
        do {
            try data.write(to: fileURL)
            hasUnsavedChanges = false
            HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
            print("File saved successfully.")
        } catch {
            presentAlert(title: "Error", message: "Could not save file: \(error.localizedDescription)")
        }
    }

    @objc func copyContent() {
        UIPasteboard.general.string = textView.text
        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
        print("Content copied to clipboard.")
    }

    @objc func promptFindReplace() {
        let alert = UIAlertController(title: "Find and Replace", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Find"
        }
        alert.addTextField { textField in
            textField.placeholder = "Replace"
        }
        alert.addAction(UIAlertAction(title: "Replace", style: .default, handler: { _ in
            guard let findText = alert.textFields?[0].text, let replaceText = alert.textFields?[1].text else { return }
            if let currentText = self.textView.text {
                self.textView.text = currentText.replacingOccurrences(of: findText, with: replaceText)
                self.hasUnsavedChanges = true
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func undoAction() {
        textView.undoManager?.undo()
    }

    @objc func redoAction() {
        textView.undoManager?.redo()
    }

    func textViewDidChange(_ textView: UITextView) {
        hasUnsavedChanges = true
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func startAutoSaveTimer() {
        autoSaveTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(autoSave), userInfo: nil, repeats: true)
    }

    func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    @objc func autoSave() {
        if hasUnsavedChanges {
            saveChanges()
        }
    }

    func promptSaveChanges() {
        let alert = UIAlertController(title: "Unsaved Changes", message: "You have unsaved changes. Do you want to save them?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            self.saveChanges()
        }))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
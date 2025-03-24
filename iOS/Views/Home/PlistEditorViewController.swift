import UIKit

class PlistEditorViewController: UIViewController, UITextViewDelegate {
    private let fileURL: URL
    private let textView: UITextView
    private let toolbar: UIToolbar
    private var hasUnsavedChanges = false
    private var autoSaveTimer: Timer?
    
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
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        view.layer.applyFuturisticShadow()
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.delegate = self
        textView.layer.cornerRadius = 10
        textView.layer.borderColor = UIColor.systemCyan.withAlphaComponent(0.2).cgColor
        textView.layer.borderWidth = 1
        view.addSubview(textView)
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveChanges))
        let copyButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(copyContent))
        let findReplaceButton = UIBarButtonItem(title: "Find/Replace", style: .plain, target: self, action: #selector(promptFindReplace))
        let undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undoAction))
        let redoButton = UBarButtonItem(barButtonSystemItem: .redo, target: self, action: #selector(redoAction))
        toolbar.items = [saveButton, copyButton, findReplaceButton, undoButton, redoButton, UIBarButtonItem.flexibleSpace()]
        toolbar.tintColor = .systemCyan
        toolbar.layer.cornerRadius = 10
        view.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            textView.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -10),
            toolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            toolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        textView.isAccessibilityElement = true
        textView.accessibilityLabel = "Plist Editor"
        toolbar.isAccessibilityElement = true
        toolbar.accessibilityLabel = "Toolbar"
    }
    
    private func loadFileContent() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(contentsOf: self.fileURL, encoding: .utf8)
                DispatchQueue.main.async {
                    self.textView.text = fileContent
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Failed to load file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func saveChanges() {
        guard let newText = textView.text else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try newText.write(to: self.fileURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    self.hasUnsavedChanges = false
                    self.presentAlert(title: "Success", message: "File saved successfully.")
                    HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Failed to save file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func copyContent() {
        UIPasteboard.general.string = textView.text
        presentAlert(title: "Copied", message: "Content copied to clipboard.")
        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
    }
    
    @objc private func undoAction() {
        textView.undoManager?.undo()
    }
    
    @objc private func redoAction() {
        textView.undoManager?.redo()
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
            guard let findText = alert.textFields?[0].text, let replaceText = alert.textFields?[1].text else { return }
            self?.findAndReplace(findText: findText, replaceText: replaceText)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func findAndReplace(findText: String, replaceText: String) {
        guard !findText.isEmpty else { return }
        textView.text = textView.text.replacingOccurrences(of: findText, with: replaceText, options: .caseInsensitive)
        hasUnsavedChanges = true
    }
    
    private func promptSaveChanges() {
        let alert = UIAlertController(title: "Unsaved Changes", message: "Save changes before leaving?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            self?.saveChanges()
            self?.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func startAutoSaveTimer() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.autoSaveChanges()
        }
    }
    
    private func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    @objc private func autoSaveChanges() {
        if hasUnsavedChanges {
            saveChanges()
        }
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        hasUnsavedChanges = true
    }
}
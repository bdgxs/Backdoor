import UIKit

class TextEditorViewController: UIViewController, UITextViewDelegate {
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
        }
    }
    
    func setupUI() {
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
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexibleSpace, saveButton]
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
        textView.accessibilityLabel = "Text Editor"
        toolbar.isAccessibilityElement = true
        toolbar.accessibilityLabel = "Toolbar"
    }
    
    func loadFileContent() {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            textView.text = content
        } catch {
            presentAlert(title: "Error", message: "Could not load file: \(error.localizedDescription)")
        }
    }
    
    @objc func saveChanges() {
        guard let text = textView.text else { return }
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            hasUnsavedChanges = false
            HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
            presentAlert(title: "Success", message: "File saved successfully.")
        } catch {
            presentAlert(title: "Error", message: "Could not save file: \(error.localizedDescription)")
        }
    }
    
    func promptSaveChanges() {
        let alert = UIAlertController(title: "Unsaved Changes", message: "Save changes before leaving?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            self.saveChanges()
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func startAutoSaveTimer() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.autoSaveChanges()
        }
    }
    
    func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    @objc func autoSaveChanges() {
        if hasUnsavedChanges {
            saveChanges()
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        hasUnsavedChanges = true
    }
    
    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
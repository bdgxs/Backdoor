import UIKit

class TextEditorViewController: UIViewController, UITextViewDelegate {
    private var fileURL: URL
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
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexibleSpace, saveButton] // Arrange buttons properly
        view.addSubview(toolbar)

        // Constraints for text view
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: toolbar.topAnchor) // Position text view above toolbar
        ])

        // Constraints for toolbar
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func loadFileContent() {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            textView.text = content
        } catch {
            print("Error loading file content: \(error)")
            presentAlert(title: "Error", message: "Could not load file content.")
        }
    }

    @objc private func saveChanges() {
        guard let text = textView.text else {
            return
        }
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            hasUnsavedChanges = false
            print("File saved successfully.")
        } catch {
            print("Error saving file: \(error)")
            presentAlert(title: "Error", message: "Could not save file.")
        }
    }

    private func promptSaveChanges() {
        let alert = UIAlertController(title: "Unsaved Changes", message: "You have unsaved changes. Do you want to save them before leaving?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            self?.saveChanges()
            self?.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func startAutoSaveTimer() {
        autoSaveTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(autoSaveChanges), userInfo: nil, repeats: true)
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

    func textViewDidChange(_ textView: UITextView) {
        hasUnsavedChanges = true
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

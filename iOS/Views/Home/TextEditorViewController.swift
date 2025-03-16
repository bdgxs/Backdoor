import UIKit

class TextEditorViewController: UIViewController {
    private var fileURL: URL
    private var textView: UITextView!
    private var toolbar: UIToolbar!
    private var hasUnsavedChanges = false

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
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Setup text view
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.delegate = self
        view.addSubview(textView)

        // Setup toolbar
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveChanges))
        let copyButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(copyContent))
        toolbar.items = [saveButton, copyButton, UIBarButtonItem.flexibleSpace()]
        view.addSubview(toolbar)

        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveChanges))

        // Setup constraints
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadFileContent() {
        do {
            let fileContent = try String(contentsOf: fileURL)
            textView.text = fileContent
        } catch {
            presentAlert(title: "Error", message: "Failed to load file content: \(error.localizedDescription)")
        }
    }

    @objc private func saveChanges() {
        guard let newText = textView.text else { return }
        do {
            try newText.write(to: fileURL, atomically: true, encoding: .utf8)
            hasUnsavedChanges = false
            presentAlert(title: "Success", message: "File saved successfully.")
        } catch {
            presentAlert(title: "Error", message: "Failed to save file: \(error.localizedDescription)")
        }
    }

    @objc private func copyContent() {
        UIPasteboard.general.string = textView.text
        presentAlert(title: "Copied", message: "Content copied to clipboard.")
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if hasUnsavedChanges {
            promptSaveChanges()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

extension TextEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        hasUnsavedChanges = true
    }
}
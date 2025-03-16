import UIKit

class PlistEditorViewController: UIViewController, UITextViewDelegate {
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
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadFileContent() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: self.fileURL)
                if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                    DispatchQueue.main.async {
                        self.textView.text = self.convertPlistToString(plist: plist)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Failed to load plist content: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func saveChanges() {
        guard let plistString = textView.text else { return }
        let plistData = plistString.data(using: .utf8)!
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try plistData.write(to: self.fileURL)
                self.hasUnsavedChanges = false
                DispatchQueue.main.async {
                    self.presentAlert(title: "Success", message: "File saved successfully.")
                }
            } catch {
                DispatchQueue.main.async {
                    self.present
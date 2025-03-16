import UIKit

class PlistEditorViewController: UIViewController {

    private let fileURL: URL
    private var textView: UITextView!
    private var toolbar: UIToolbar!

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
        textView.font = UIFont(name: "Courier", size: 14)
        view.addSubview(textView)

        // Setup toolbar
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(savePlistContent))
        let copyButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(copyPlistContent))
        toolbar.items = [saveButton, copyButton, UIBarButtonItem.flexibleSpace()]
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
        do {
            let data = try Data(contentsOf: fileURL)
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                textView.text = convertPlistToString(plist: plist)
            }
        } catch {
            presentAlert(title: "Error", message: "Failed to load plist content: \(error.localizedDescription)")
        }
    }

    @objc private func savePlistContent() {
        guard let content = textView.text else { return }
        do {
            let plist = try convertStringToPlist(content: content)
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: fileURL)
            presentAlert(title: "Success", message: "File saved successfully.")
        } catch {
            presentAlert(title: "Error", message: "Failed to save plist content: \(error.localizedDescription)")
        }
    }

    @objc private func copyPlistContent() {
        UIPasteboard.general.string = textView.text
        presentAlert(title: "Copied", message: "Plist content copied to clipboard.")
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func convertPlistToString(plist: [String: Any]) -> String {
        return plist.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
    }

    private func convertStringToPlist(content: String) throws -> [String: Any] {
        let lines = content.split(separator: "\n")
        var plist = [String: Any]()
        for line in lines {
            let components = line.split(separator: ":")
            guard components.count == 2 else { throw NSError(domain: "InvalidFormat", code: 1, userInfo: nil) }
            let key = String(components[0]).trimmingCharacters(in: .whitespaces)
            let value = String(components[1]).trimmingCharacters(in: .whitespaces)
            plist[key] = value
        }
        return plist
    }
}
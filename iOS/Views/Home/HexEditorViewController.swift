import UIKit

class HexEditorViewController: UIViewController {

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
        textView.font = UIFont(name: "Courier", size: 12)
        view.addSubview(textView)

        // Setup toolbar
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveHexContent))
        let copyButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(copyHexContent))
        let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(promptSearch))
        toolbar.items = [saveButton, copyButton, UIBarButtonItem.flexibleSpace(), searchButton]
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
            let hexString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
            textView.text = hexString
        } catch {
            presentAlert(title: "Error", message: "Failed to load file content: \(error.localizedDescription)")
        }
    }

    @objc private func saveHexContent() {
        guard let hexString = textView.text else { return }
        let hexValues = hexString.split(separator: " ").map(String.init)
        var data = Data()
        for hex in hexValues {
            if let byte = UInt8(hex, radix: 16) {
                data.append(byte)
            } else {
                presentAlert(title: "Error", message: "Invalid hex value: \(hex)")
                return
            }
        }
        do {
            try data.write(to: fileURL)
            presentAlert(title: "Success", message: "File saved successfully.")
        } catch {
            presentAlert(title: "Error", message: "Failed to save file: \(error.localizedDescription)")
        }
    }

    @objc private func copyHexContent() {
        UIPasteboard.general.string = textView.text
        presentAlert(title: "Copied", message: "Hex content copied to clipboard.")
    }

    @objc private func promptSearch() {
        let alert = UIAlertController(title: "Search Hex", message: "Enter hex value to search:", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g., 4a 6f 68 6e"
        }
        alert.addAction(UIAlertAction(title: "Search", style: .default, handler: { [weak self] _ in
            if let hexValue = alert.textFields?.first?.text {
                self?.searchHexValue(hexValue)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func searchHexValue(_ hexValue: String) {
        guard let hexContent = textView.text else { return }
        if let range = hexContent.range(of: hexValue, options: .caseInsensitive) {
            textView.scrollRangeToVisible(NSRange(range, in: hexContent))
            textView.becomeFirstResponder()
            textView.selectedRange = NSRange(range, in: hexContent)
        } else {
            presentAlert(title: "Not Found", message: "Hex value not found in the file.")
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
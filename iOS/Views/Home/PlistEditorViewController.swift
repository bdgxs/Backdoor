import UIKit

class PlistEditorViewController: UIViewController {
    private var fileURL: URL
    private var textView: UITextView!

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
        textView = UITextView(frame: view.bounds)
        view.addSubview(textView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveChanges))
    }

    private func loadFileContent() {
        if let data = try? Data(contentsOf: fileURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil),
           let plistData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0),
           let plistString = String(data: plistData, encoding: .utf8) {
            textView.text = plistString
        }
    }

    @objc private func saveChanges() {
        if let newText = textView.text,
           let data = newText.data(using: .utf8),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil),
           let plistData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0) {
            try? plistData.write(to: fileURL)
        }
        navigationController?.popViewController(animated: true)
    }
}
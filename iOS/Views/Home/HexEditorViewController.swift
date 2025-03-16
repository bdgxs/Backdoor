import UIKit

class HexEditorViewController: UIViewController {
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
        if let data = try? Data(contentsOf: fileURL) {
            textView.text = data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
        }
    }

    @objc private func saveChanges() {
        let hexString = textView.text.replacingOccurrences(of: " ", with: "")
        var data = Data()
        var byteString = ""
        for (index, char) in hexString.enumerated() {
            byteString.append(char)
            if index % 2 != 0 {
                let num = UInt8(byteString, radix: 16)!
                data.append(num)
                byteString = ""
            }
        }
        try? data.write(to: fileURL)
        navigationController?.popViewController(animated: true)
    }
}
import UIKit

class HexEditorViewController: UIViewController {

    private let fileURL: URL
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
        view.backgroundColor = .black
        textView = UITextView(frame: view.bounds)
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.font = UIFont(name: "Courier", size: 12)
        view.addSubview(textView)
    }

    private func loadFileContent() {
        do {
            let data = try Data(contentsOf: fileURL)
            let hexString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
            textView.text = hexString
        } catch {
            print("Failed to load file content: \(error)")
        }
    }
}
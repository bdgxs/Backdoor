import UIKit

class TextEditorViewController: UIViewController {
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
        if let fileContent = try? String(contentsOf: fileURL) {
            textView.text = fileContent
        }
    }

    @objc private func saveChanges() {
        if let newText = textView.text {
            try? newText.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        navigationController?.popViewController(animated: true)
    }
}
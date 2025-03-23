import UIKit

class FileTableViewCell: UITableViewCell {
    let fileIconImageView = UIImageView()
    let fileNameLabel = UILabel()
    let fileSizeLabel = UILabel()
    let fileDateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.addSubview(fileIconImageView)
        contentView.addSubview(fileNameLabel)
        contentView.addSubview(fileSizeLabel)
        contentView.addSubview(fileDateLabel)

        fileIconImageView.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileDateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            fileIconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fileIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fileIconImageView.widthAnchor.constraint(equalToConstant: 40),
            fileIconImageView.heightAnchor.constraint(equalToConstant: 40),

            fileNameLabel.leadingAnchor.constraint(equalTo: fileIconImageView.trailingAnchor, constant: 16),
            fileNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            fileNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),

            fileSizeLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 4),

            fileDateLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            fileDateLabel.topAnchor.constraint(equalTo: fileSizeLabel.bottomAnchor, constant: 4),
            fileDateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        fileIconImageView.isAccessibilityElement = true
        fileIconImageView.accessibilityLabel = "File Icon"
        fileNameLabel.isAccessibilityElement = true
        fileNameLabel.accessibilityLabel = "File Name"
        fileSizeLabel.isAccessibilityElement = true
        fileSizeLabel.accessibilityLabel = "File Size"
        fileDateLabel.isAccessibilityElement = true
        fileDateLabel.accessibilityLabel = "File Date"
    }

    func configure(with file: File) {
        fileNameLabel.text = file.name
        fileSizeLabel.text = "\(file.size) bytes"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        fileDateLabel.text = dateFormatter.string(from: file.date)
        fileIconImageView.image = UIImage(systemName: file.iconName)
        accessibilityElements = [fileIconImageView, fileNameLabel, fileSizeLabel, fileDateLabel]
    }
}

// File model class to hold file information
class File {
    let url: URL
    var name: String {
        return url.lastPathComponent
    }
    var size: UInt64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? UInt64 ?? 0
    }
    var date: Date {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date ?? Date.distantPast
    }
    var iconName: String {
        let extensionString = url.pathExtension.lowercased()
        switch extensionString {
        case "txt", "md": return "doc.text"
        case "zip": return "doc.zipper"
        default: return "doc"
        }
    }

    init(url: URL) {
        self.url = url
    }
}
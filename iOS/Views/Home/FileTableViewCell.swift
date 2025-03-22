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

    private func setupUI() {
        // Configure and add subviews to contentView
        contentView.addSubview(fileIconImageView)
        contentView.addSubview(fileNameLabel)
        contentView.addSubview(fileSizeLabel)
        contentView.addSubview(fileDateLabel)

        // Setup layout constraints
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
    }

    func configure(with file: File) {
        // Configure the cell with file data
        fileNameLabel.text = file.name
        fileSizeLabel.text = "\(file.size) bytes"
        fileDateLabel.text = "\(file.date)"

        // Set an appropriate icon for the file type
        if file.type == "txt" {
            fileIconImageView.image = UIImage(systemName: "doc.text")
        } else if file.type == "zip" {
            fileIconImageView.image = UIImage(systemName: "archivebox")
        } else if file.type == "" {
            fileIconImageView.image = UIImage(systemName: "folder")
        }
         else {
            fileIconImageView.image = UIImage(systemName: "doc")
        }
    }
}

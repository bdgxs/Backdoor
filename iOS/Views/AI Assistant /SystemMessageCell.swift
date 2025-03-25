import UIKit

class SystemMessageCell: UITableViewCell {
    private let messageLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .systemGray
        messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        messageLabel.textAlignment = .center
        
        contentView.addSubview(messageLabel)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
    
    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
    }
}
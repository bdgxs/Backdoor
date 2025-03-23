import UIKit

class HomeViewUI {
    static let navigationBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.barTintColor = .systemBlue
        navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBar.isAccessibilityElement = true
        navBar.accessibilityLabel = "Navigation Bar"
        return navBar
    }()
    
    static let fileListTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.isAccessibilityElement = true
        tableView.accessibilityLabel = "File List Table"
        return tableView
    }()
    
    static let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .systemBlue
        indicator.isAccessibilityElement = true
        indicator.accessibilityLabel = "Activity Indicator"
        return indicator
    }()
    
    static let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload File", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.isAccessibilityElement = true
        button.accessibilityLabel = "Upload File Button"
        return button
    }()
}
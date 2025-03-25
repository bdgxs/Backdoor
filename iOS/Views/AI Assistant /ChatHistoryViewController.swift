import UIKit

class ChatHistoryViewController: UITableViewController {
    private var sessions: [ChatSession] = []
    var didSelectSession: ((ChatSession) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat History"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissVC))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .systemGray6
        loadSessions()
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    private func loadSessions() {
        sessions = CoreDataManager.shared.getChatSessions()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let session = sessions[indexPath.row]
        cell.textLabel?.text = session.title
        cell.backgroundColor = .systemBackground
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let session = sessions[indexPath.row]
        didSelectSession?(session)
        dismiss(animated: true)
    }
}
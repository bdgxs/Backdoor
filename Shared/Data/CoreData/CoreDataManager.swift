import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    private let persistentContainer: NSPersistentContainer
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private init() {
        persistentContainer = NSPersistentContainer(name: "YourModelName")
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }

    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: - Chat Session Management

    func createChatSession(title: String) throws -> ChatSession {
        let session = ChatSession(context: context)
        session.sessionID = UUID().uuidString
        session.title = title
        session.creationDate = Date()
        try saveContext()
        return session
    }

    func addMessage(to session: ChatSession, sender: String, content: String) throws -> ChatMessage {
        let message = ChatMessage(context: context)
        message.messageID = UUID().uuidString
        message.sender = sender
        message.content = content
        message.timestamp = Date()
        message.session = session
        try saveContext()
        return message
    }

    func getMessages(for session: ChatSession) -> [ChatMessage] {
        let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "session == %@", session)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            return try context.fetch(request)
        } catch {
            Debug.shared.log(message: "CoreDataManager.getMessages: \(error.localizedDescription)", type: .error)
            return []
        }
    }

    func getChatSessions() -> [ChatSession] {
        let request: NSFetchRequest<ChatSession> = ChatSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            Debug.shared.log(message: "CoreDataManager.getChatSessions: \(error.localizedDescription)", type: .error)
            return []
        }
    }
}

// Extension to NSPersistentContainer for performing background tasks with async/await support.
extension NSPersistentContainer {
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        await withCheckedContinuation { continuation in
            self.performBackgroundTask { context in
                let result = block(context)
                continuation.resume(returning: result)
            }
        }
    }
}

// Placeholder for a debug logging utility (replace with your actual implementation).
class Debug {
    static let shared = Debug()

    enum LogType {
        case error, critical, debug
    }

    func log(message: String, type: LogType) {
        print("[\(type)] \(message)")
    }
}
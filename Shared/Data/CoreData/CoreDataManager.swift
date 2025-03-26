import CoreData
import UIKit
import Logger

final class CoreDataManager {
    static let shared = CoreDataManager()

    init() {}
    deinit {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Feather")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Debug.shared.log(message: "CoreDataManager.saveContext: \(error)", type: .critical)
            }
        }
    }

    /// Clear all objects from fetch request.
    func clear<T: NSManagedObject>(request: NSFetchRequest<T>, context: NSManagedObjectContext? = nil) {
        let context = context ?? self.context
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: (request as? NSFetchRequest<NSFetchRequestResult>)!)
        do {
            _ = try context.execute(deleteRequest)
        } catch {
            Debug.shared.log(message: "CoreDataManager.clear: \(error.localizedDescription)", type: .error)
        }
    }

    func loadImage(from iconUrl: URL?) -> UIImage? {
        guard let iconUrl = iconUrl else { return nil }
        return UIImage(contentsOfFile: iconUrl.path)
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

extension NSPersistentContainer {
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        await withCheckedContinuation({ continuation in
            self.performBackgroundTask { context in
                let result = block(context)
                continuation.resume(returning: result)
            }
        })
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
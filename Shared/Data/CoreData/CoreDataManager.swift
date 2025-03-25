import CoreData
import UIKit

/// A singleton class responsible for managing Core Data operations in the app.
final class CoreDataManager {
    /// Shared instance of CoreDataManager for singleton access.
    static let shared = CoreDataManager()
    
    private init() {}
    deinit {}
    
    /// The persistent container for Core Data, configured with the "Feather" data model.
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Feather")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        // Set merge policy to handle conflicts between contexts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    /// The main view context for UI-related Core Data operations.
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    /// Saves changes in the current context, throwing an error if the save fails.
    func saveContext() throws {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Debug.shared.log(message: "CoreDataManager.saveContext: \(error)", type: .critical)
                throw error
            }
        }
    }
    
    /// Clears all objects matching the given fetch request from the specified context.
    func clear<T: NSManagedObject>(request: NSFetchRequest<T>, context: NSManagedObjectContext? = nil) throws {
        let context = context ?? self.context
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as? NSFetchRequest<NSFetchRequestResult> ?? NSFetchRequest())
        do {
            _ = try context.execute(deleteRequest)
            try context.save()
        } catch {
            Debug.shared.log(message: "CoreDataManager.clear: \(error.localizedDescription)", type: .error)
            throw error
        }
    }
    
    /// Loads an image from a local file URL, returning nil if the URL is invalid or the image cannot be loaded.
    func loadImage(from iconUrl: URL?) -> UIImage? {
        guard let iconUrl = iconUrl else { return nil }
        return UIImage(contentsOfFile: iconUrl.path)
    }
    
    // MARK: - Chat Session Management
    
    /// Creates a new chat session with the given title.
    /// - Parameter title: The title of the chat session.
    /// - Returns: The newly created `ChatSession` object.
    /// - Throws: An error if saving the context fails.
    func createChatSession(title: String) throws -> ChatSession {
        let session = ChatSession(context: context)
        session.sessionID = UUID().uuidString
        session.title = title
        session.creationDate = Date()
        try saveContext()
        return session
    }
    
    /// Adds a new message to the specified chat session.
    /// - Parameters:
    ///   - session: The `ChatSession` to add the message to.
    ///   - sender: The sender of the message (e.g., "user" or "AI").
    ///   - content: The content of the message.
    /// - Returns: The newly created `ChatMessage` object.
    /// - Throws: An error if saving the context fails.
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
    
    /// Retrieves all messages for a given chat session, sorted by timestamp.
    /// - Parameter session: The `ChatSession` to fetch messages for.
    /// - Returns: An array of `ChatMessage` objects, or an empty array if fetching fails.
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
    
    /// Retrieves all chat sessions, sorted by creation date in descending order.
    /// - Returns: An array of `ChatSession` objects, or an empty array if fetching fails.
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

/// Extension to NSPersistentContainer for performing background tasks with async/await support.
extension NSPersistentContainer {
    /// Executes a block on a background context and returns the result asynchronously.
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        await withCheckedContinuation { continuation in
            self.performBackgroundTask { context in
                let result = block(context)
                continuation.resume(returning: result)
            }
        }
    }
}

/// Placeholder for a debug logging utility (replace with your actual implementation).
class Debug {
    static let shared = Debug()
    
    enum LogType {
        case error, critical
    }
    
    func log(message: String, type: LogType) {
        print("[\(type)] \(message)")
    }
}
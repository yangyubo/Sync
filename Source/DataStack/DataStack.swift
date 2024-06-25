import Foundation
import CoreData

public enum DataStackStoreType: Int {
    case inMemory, sqLite

    var type: String {
        switch self {
        case .inMemory:
            return NSInMemoryStoreType
        case .sqLite:
            return NSSQLiteStoreType
        }
    }
}

public class DataStack {

    public var model: NSManagedObjectModel {
        return persistentContainer.managedObjectModel
    }

    private let persistentContainer: NSPersistentContainer
    
    private let backgroundContextName = "DataStack.backgroundContextName"

    /**
     The context for the main queue. Please do not use this to mutate data, use `performInNewBackgroundContext`
     instead.
     */
    public lazy var mainContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.persistentStoreCoordinator = self.persistentStoreCoordinator

        NotificationCenter.default.addObserver(self, selector: #selector(DataStack.mainContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: context)

        return context
    }()

    /**
     The context for the main queue. Please do not use this to mutate data, use `performBackgroundTask`
     instead.
     */
    public var viewContext: NSManagedObjectContext {
        return self.mainContext
    }

    private lazy var writerContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: DataStack.backgroundConcurrencyType())
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.persistentStoreCoordinator = self.persistentStoreCoordinator

        return context
    }()

    public var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        persistentContainer.persistentStoreCoordinator
    }

    /**
     Initializes a DataStack using the provided persistent container.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     */
    public init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextWillSave, object: nil)
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextDidSave, object: nil)
    }

    /**
     Returns a background context perfect for data mutability operations. Make sure to never use it on the main thread. Use `performBlock` or `performBlockAndWait` to use it.
     Saving to this context doesn't merge with the main thread. This context is specially useful to run operations that don't block the main thread. To refresh your main thread objects for
     example when using a NSFetchedResultsController use `try self.fetchedResultsController.performFetch()`.
     */
    public func newNonMergingBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: DataStack.backgroundConcurrencyType())
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        return context
    }

    /**
     Returns a background context perfect for data mutability operations. Make sure to never use it on the main thread. Use `performBlock` or `performBlockAndWait` to use it.
     */
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: DataStack.backgroundConcurrencyType())
        context.name = backgroundContextName
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        NotificationCenter.default.addObserver(self, selector: #selector(DataStack.backgroundContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: context)

        return context
    }

    /**
     Returns a background context perfect for data mutability operations.
     - parameter operation: The block that contains the created background context.
     */
    public func performInNewBackgroundContext(_ operation: @escaping (_ backgroundContext: NSManagedObjectContext) -> Void) {
        let context = self.newBackgroundContext()
        let contextBlock: @convention(block) () -> Void = {
            operation(context)
        }
        let blockObject: AnyObject = unsafeBitCast(contextBlock, to: AnyObject.self)
        context.perform(DataStack.performSelectorForBackgroundContext(), with: blockObject)
    }

    /**
     Returns a background context perfect for data mutability operations.
     - parameter operation: The block that contains the created background context.
     */
    public func performBackgroundTask(operation: @escaping (_ backgroundContext: NSManagedObjectContext) -> Void) {
        self.performInNewBackgroundContext(operation)
    }

    func saveMainThread(completion: ((_ error: NSError?) -> Void)?) {
        var writerContextError: NSError?
        let writerContextBlock: @convention(block) () -> Void = {
            do {
                try self.writerContext.save()
                if TestCheck.isTesting {
                    completion?(nil)
                }
            } catch let parentError as NSError {
                writerContextError = parentError
            }
        }
        let writerContextBlockObject: AnyObject = unsafeBitCast(writerContextBlock, to: AnyObject.self)

        let mainContextBlock: @convention(block) () -> Void = {
            self.writerContext.perform(DataStack.performSelectorForBackgroundContext(), with: writerContextBlockObject)
            DispatchQueue.main.async {
                completion?(writerContextError)
            }
        }
        let mainContextBlockObject: AnyObject = unsafeBitCast(mainContextBlock, to: AnyObject.self)
        self.mainContext.perform(DataStack.performSelectorForBackgroundContext(), with: mainContextBlockObject)
    }

    // Drops the database.
    @objc public func drop(completion: ((_ error: NSError?) -> Void)? = nil) {
        self.writerContext.performAndWait {
            self.writerContext.reset()

            self.mainContext.performAndWait {
                self.mainContext.reset()

                self.persistentStoreCoordinator.performAndWait {
                    for store in self.persistentStoreCoordinator.persistentStores {
                        guard let storeURL = store.url else { continue }
                        try! self.oldDrop(storeURL: storeURL)
                    }

                    DispatchQueue.main.async {
                        completion?(nil)
                    }
                }
            }
        }
    }

    // Required for iOS 8 Compatibility.
    func oldDrop(storeURL: URL) throws {
        let storePath = storeURL.path
        let sqliteFile = (storePath as NSString).deletingPathExtension
        let fileManager = FileManager.default

        self.writerContext.reset()
        self.mainContext.reset()

        let shm = sqliteFile + ".sqlite-shm"
        if fileManager.fileExists(atPath: shm) {
            do {
                try fileManager.removeItem(at: NSURL.fileURL(withPath: shm))
            } catch let error as NSError {
                throw NSError(info: "Could not delete persistent store shm", previousError: error)
            }
        }

        let wal = sqliteFile + ".sqlite-wal"
        if fileManager.fileExists(atPath: wal) {
            do {
                try fileManager.removeItem(at: NSURL.fileURL(withPath: wal))
            } catch let error as NSError {
                throw NSError(info: "Could not delete persistent store wal", previousError: error)
            }
        }

        if fileManager.fileExists(atPath: storePath) {
            do {
                try fileManager.removeItem(at: storeURL)
            } catch let error as NSError {
                throw NSError(info: "Could not delete sqlite file", previousError: error)
            }
        }
    }

    /// Sends a request to all the persistent stores associated with the receiver.
    ///
    /// - Parameters:
    ///   - request: A fetch, save or delete request.
    ///   - context: The context against which request should be executed.
    /// - Returns: An array containing managed objects, managed object IDs, or dictionaries as appropriate for a fetch request; an empty array if request is a save request, or nil if an error occurred.
    /// - Throws: If an error occurs, upon return contains an NSError object that describes the problem.
    @objc public func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext) throws -> Any {
        return try self.persistentStoreCoordinator.execute(request, with: context)
    }

    // Can't be private, has to be internal in order to be used as a selector.
    @objc func mainContextDidSave(_ notification: Notification) {
        self.saveMainThread { error in
            if let error = error {
                fatalError("Failed to save objects in main thread: \(error)")
            }
        }
    }

    // Can't be private, has to be internal in order to be used as a selector.
    @objc func backgroundContextDidSave(_ notification: Notification) throws {
        let context = notification.object as? NSManagedObjectContext
        guard context?.name == backgroundContextName else {
            return
        }

        if Thread.isMainThread && TestCheck.isTesting == false {
            throw NSError(info: "Background context saved in the main thread. Use context's `performBlock`", previousError: nil)
        } else {
            let contextBlock: @convention(block) () -> Void = {
                self.mainContext.mergeChanges(fromContextDidSave: notification)
            }
            let blockObject: AnyObject = unsafeBitCast(contextBlock, to: AnyObject.self)
            self.mainContext.perform(DataStack.performSelectorForBackgroundContext(), with: blockObject)
        }
    }

    private static func backgroundConcurrencyType() -> NSManagedObjectContextConcurrencyType {
        return TestCheck.isTesting ? .mainQueueConcurrencyType : .privateQueueConcurrencyType
    }

    private static func performSelectorForBackgroundContext() -> Selector {
        return TestCheck.isTesting ? NSSelectorFromString("performBlockAndWait:") : NSSelectorFromString("performBlock:")
    }
}

extension NSManagedObjectModel {
    convenience init(bundle: Bundle, name: String) {
        if let momdModelURL = bundle.url(forResource: name, withExtension: "momd") {
            self.init(contentsOf: momdModelURL)!
        } else if let momModelURL = bundle.url(forResource: name, withExtension: "mom") {
            self.init(contentsOf: momModelURL)!
        } else {
            self.init()
        }
    }
}

extension NSError {
    convenience init(info: String, previousError: NSError?) {
        if let previousError = previousError {
            var userInfo = previousError.userInfo
            if let _ = userInfo[NSLocalizedFailureReasonErrorKey] {
                userInfo["Additional reason"] = info
            } else {
                userInfo[NSLocalizedFailureReasonErrorKey] = info
            }

            self.init(domain: previousError.domain, code: previousError.code, userInfo: userInfo)
        } else {
            var userInfo = [String: String]()
            userInfo[NSLocalizedDescriptionKey] = info
            self.init(domain: "com.SyncDB.DataStack", code: 9999, userInfo: userInfo)
        }
    }
}

extension FileManager {
    /// The directory URL for the sqlite file.
    public static var sqliteDirectoryURL: URL {
        #if os(tvOS)
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
        #else
            if TestCheck.isTesting {
                return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
            } else {
                return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
            }
        #endif
    }
}

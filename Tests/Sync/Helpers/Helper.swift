import XCTest
import CoreData
import Sync

@objc class Helper: NSObject {
    class func objectsFromJSON(_ fileName: String) -> Any {
        let objects = try! JSON.from(fileName)!

        return objects
    }

    class func countForEntity(_ entityName: String, inContext context: NSManagedObjectContext) -> Int {
        return self.countForEntity(entityName, predicate: nil, inContext: context)
    }

    class func countForEntity(_ entityName: String, predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        let count = try! context.count(for: fetchRequest)

        return count
    }

    class func fetchEntity(_ entityName: String, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: nil, sortDescriptors: nil, inContext: context)
    }

    class func fetchEntity(_ entityName: String, predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: predicate, sortDescriptors: nil, inContext: context)
    }

    class func fetchEntity(_ entityName: String, sortDescriptors: [NSSortDescriptor]?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: nil, sortDescriptors: sortDescriptors, inContext: context)
    }

    class func fetchEntity(_ entityName: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        let objects = try! context.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()

        return objects
    }

    class func insertEntity(_ name: String, container: NSPersistentContainer) -> NSManagedObject {
        let entity = NSEntityDescription.entity(forEntityName: name, in: container.viewContext)!
        return NSManagedObject(entity: entity, insertInto: container.viewContext)
    }

}

extension NSPersistentContainer {
    
    convenience init(modelName: String, inMemory: Bool = true, storeName: String? = nil) {
        let modelURL = Bundle.module.url(forResource: modelName, withExtension: "momd")!
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Can't get \(modelName).momd in Bundle")
        }
        
        defer {
            self.testSetup(inMemory: inMemory, storeName: storeName)
        }
        
        self.init(name: modelName, managedObjectModel: model)
    }
    
}

private extension NSPersistentContainer {
    
    /// The directory URL for the sqlite file.
    static var sqliteDirectoryURL: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
    
    func testSetup(inMemory: Bool, storeName: String?) {
        if inMemory {
            self.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeName = storeName {
            let storeFileName = storeName + ".sqlite"
            let storeURL = Self.sqliteDirectoryURL.appendingPathComponent(storeFileName)
            self.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        }
        
        // enable Persistent History Tracking
        self.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        self.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        self.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }
        
        // Merge settings
        self.viewContext.automaticallyMergesChangesFromParent = true
        self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
}


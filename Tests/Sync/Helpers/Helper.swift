import XCTest
import CoreData
import Sync

@objc class Helper: NSObject {
    class func objectsFromJSON(_ fileName: String) -> Any {
        let objects = try! JSON.from(fileName)!

        return objects
    }

    class func dataStackWithModelName(_ modelName: String) -> DataStack {
        let dataStack = DataStack(modelName: modelName, inMemory: false)
        return dataStack
    }

    class func persistentStoreWithModelName(_ modelName: String) -> NSPersistentContainer {
        let momdModelURL = Bundle.module.url(forResource: modelName, withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: momdModelURL)!
        let persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)
        try! persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

        return persistentContainer
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

    class func dataStackWithModelName(_ modelName: String, inMemory: Bool = false) -> DataStack {
        let dataStack = DataStack(modelName: modelName, inMemory: inMemory)
        return dataStack
    }

    class func insertEntity(_ name: String, dataStack: DataStack) -> NSManagedObject {
        let entity = NSEntityDescription.entity(forEntityName: name, in: dataStack.mainContext)!
        return NSManagedObject(entity: entity, insertInto: dataStack.mainContext)
    }

}

extension DataStack {
    
    convenience init(modelName: String, inMemory: Bool, storeName: String? = nil) {
        let modelURL = Bundle.module.url(forResource: modelName, withExtension: "momd")!
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Can't get \(modelName).momd in Bundle")
        }
        
        let container = NSPersistentContainer(name: "CoreSSH", managedObjectModel: model)
        container.testSetup(inMemory: inMemory, storeName: storeName)
        self.init(persistentContainer: container)
    }
    
}


private extension NSPersistentContainer {
    
    func testSetup(inMemory: Bool, storeName: String?) {
        if inMemory {
            self.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeName = storeName {
            let storeFileName = storeName + ".sqlite"
            let storeURL = FileManager.sqliteDirectoryURL.appendingPathComponent(storeFileName)
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
        
        // TODO: remove in future release
        // https://mjtsai.com/blog/2023/08/15/turning-off-core-data-persistent-history-tracking/
//        if !iCloudSync, !CorePreferences.shared._syncKeepPersistentHistory {
//            let request = NSPersistentHistoryChangeRequest.deleteHistory(before: .distantFuture)
//            self.viewContext.perform {
//                _ = try? self.viewContext.execute(request)
//                CorePreferences.shared._syncKeepPersistentHistory = true
//            }
//        }
        
        do {
            try self.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation:\(error)")
        }
    }
    
}


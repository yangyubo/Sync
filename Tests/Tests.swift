import XCTest
import CoreData
@testable import Sync

extension XCTestCase {
    
    func createContainer(inMemory: Bool = true) -> NSPersistentContainer {
        return NSPersistentContainer(modelName: "ModelGroup", inMemory: inMemory)
    }
    
    func dropContainer(_ container: NSPersistentContainer) {
        container.viewContext.performAndWait {
            container.viewContext.reset()
        }
        
        for store in container.persistentStoreCoordinator.persistentStores {
            guard let storeURL = store.url else { continue }
            // , let storeType = NSPersistentStore.StoreType(rawValue: store.type)
            try? container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: NSPersistentStore.StoreType(rawValue: store.type))
        }
    }

    @discardableResult
    func insertUser(in context: NSManagedObjectContext) -> NSManagedObject {
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
        user.setValue(NSNumber(value: 1), forKey: "remoteID")
        user.setValue("Joshua Ivanof", forKey: "name")
        try! context.save()

        return user
    }

    func fetch(in context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "User")
        let objects = try! context.fetch(request)

        return objects
    }
}

class InitializerTests: XCTestCase {
    func testInitializeUsingXCDataModel() {
        let container = NSPersistentContainer(modelName: "SimpleModel", inMemory: true)

        self.insertUser(in: container.viewContext)
        let objects = self.fetch(in: container.viewContext)
        XCTAssertEqual(objects.count, 1)
    }

    // xcdatamodeld is a container for .xcdatamodel files. It's used for versioning and migration.
    // When moving from v1 of the model to v2, you add a new xcdatamodel to it that has v2 along with the mapping model.
    func testInitializeUsingXCDataModeld() {
        let container = self.createContainer()

        self.insertUser(in: container.viewContext)
        let objects = self.fetch(in: container.viewContext)
        XCTAssertEqual(objects.count, 1)
    }

    func testInitializingUsingNSManagedObjectModel() {
        let container = NSPersistentContainer(modelName: "ModelGroup", inMemory: true)

        self.insertUser(in: container.viewContext)
        let objects = self.fetch(in: container.viewContext)
        XCTAssertEqual(objects.count, 1)
    }
}

class Tests: XCTestCase {

    func testBackgroundContextSave() {
        let container = self.createContainer()
        
        let expectation = expectation(description: "Wait end")
        container.performBackgroundTask { backgroundContext in
            self.insertUser(in: backgroundContext)

            let objects = self.fetch(in: backgroundContext)
            XCTAssertEqual(objects.count, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)

        let objects = self.fetch(in: container.viewContext)
        XCTAssertEqual(objects.count, 1)
    }

    func testNewBackgroundContextSave() {
        var synchronous = false
        let container = self.createContainer()
        
        let backgroundContext = container.newBackgroundContext()
        
        backgroundContext.performAndWait {
            synchronous = true
            self.insertUser(in: backgroundContext)
            let objects = self.fetch(in: backgroundContext)
            XCTAssertEqual(objects.count, 1)
        }

        let objects = self.fetch(in: container.viewContext)
        XCTAssertEqual(objects.count, 1)

        XCTAssertTrue(synchronous)
    }

    func testRequestWithDictionaryResultType() {
        let container = self.createContainer()
        self.insertUser(in: container.viewContext)

        let request = NSFetchRequest<NSManagedObject>(entityName: "User")
        let objects = try! container.viewContext.fetch(request)
        XCTAssertEqual(objects.count, 1)

        let expression = NSExpressionDescription()
        expression.name = "objectID"
        expression.expression = NSExpression.expressionForEvaluatedObject()
        expression.expressionResultType = .objectIDAttributeType

        let dictionaryRequest = NSFetchRequest<NSDictionary>(entityName: "User")
        dictionaryRequest.resultType = .dictionaryResultType
        dictionaryRequest.propertiesToFetch = [expression, "remoteID"]

        let dictionaryObjects = try! container.viewContext.fetch(dictionaryRequest)
        XCTAssertEqual(dictionaryObjects.count, 1)
    }
    
    func testAutomaticMigration() {
        let firstContainer = NSPersistentContainer(modelName: "SimpleModel", inMemory: false, storeName: "Shared")
        self.insertUser(in: firstContainer.viewContext)
        let objects = self.fetch(in: firstContainer.viewContext)
        XCTAssertEqual(objects.count, 1)

        // LightweightMigrationModel is a copy of DataModel with the main difference that adds the updatedDate attribute.
        let secondContainer = NSPersistentContainer(modelName: "LightweightMigrationModel", inMemory: false, storeName: "Shared")
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "remoteID = %@", NSNumber(value: 1))
        let user = try! secondContainer.viewContext.fetch(fetchRequest).first
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.value(forKey: "name") as? String, "Joshua Ivanof")
        user?.setValue(Date().addingTimeInterval(16000), forKey: "updatedDate")
        try! secondContainer.viewContext.save()

        dropContainer(firstContainer)
        dropContainer(secondContainer)
    }
}

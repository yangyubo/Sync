import XCTest

import CoreData
import Sync

class SyncTests: XCTestCase {
    
    var syncExpectation: XCTestExpectation!
    var syncCompletion: ((_ error: NSError?) -> Void)!
    var synchronous = false
    
    var backExpectation: XCTestExpectation!
    var backCompletion: (() -> Void)!
    
    override func setUp() {
        synchronous = false
        // syncExpectation = expectation(description: "Sync Expectation")
        syncCompletion = { [weak self] error in
            if let error = error {
                XCTFail(error.description)
            }
            self?.synchronous = true
            self?.syncExpectation.fulfill()
        }
        
        backCompletion = { [weak self] in
            self?.backExpectation.fulfill()
        }
    }
    
    func testSynchronous() {
        let container = NSPersistentContainer(modelName: "Camelcase")
        let objects = Helper.objectsFromJSON("camelcase.json") as! [[String: Any]]
        
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "NormalUser", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(synchronous)
        dropContainer(container)
    }

    // MARK: - Camelcase
    func testAutomaticCamelcaseMapping() {
        let container = NSPersistentContainer(modelName: "Camelcase")
        let objects = Helper.objectsFromJSON("camelcase.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "NormalUser", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let result = Helper.fetchEntity("NormalUser", inContext: container.viewContext)
        XCTAssertEqual(result.count, 1)

        let first = result.first!
        XCTAssertEqual(first.value(forKey: "etternavn") as? String, "Nuñez")
        XCTAssertEqual(first.value(forKey: "firstName") as? String, "Elvis")
        XCTAssertEqual(first.value(forKey: "fullName") as? String, "Elvis Nuñez")
        XCTAssertEqual(first.value(forKey: "numberOfChildren") as? Int, 1)
        XCTAssertEqual(first.value(forKey: "remoteID") as? String, "1")

        dropContainer(container)
    }

    // MARK: - Contacts

    func testLoadAndUpdateUsers() {
        let container = NSPersistentContainer(modelName: "Contacts")

        let objectsA = Helper.objectsFromJSON("users_a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 8)

        let objectsB = Helper.objectsFromJSON("users_b.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsB, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 6)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 7)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "secondupdated@ovium.com")

        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        dateFormat.timeZone = TimeZone(identifier: "GMT")

        let createdDate = dateFormat.date(from: "2014-02-14")
        XCTAssertEqual(result.value(forKey: "createdAt") as? Date, createdDate)

        let updatedDate = dateFormat.date(from: "2014-02-17")
        XCTAssertEqual(result.value(forKey: "updatedAt") as? Date, updatedDate)

        dropContainer(container)
    }

    func testUsersAndCompanies() {
        let container = NSPersistentContainer(modelName: "Contacts")

        let objects = Helper.objectsFromJSON("users_company.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 5)
        let user = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertEqual((user.value(forKey: "company")! as? NSManagedObject)!.value(forKey: "name") as? String, "Apple")

        XCTAssertEqual(Helper.countForEntity("Company", inContext: container.viewContext), 2)
        let company = Helper.fetchEntity("Company", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 1)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertEqual(company.value(forKey: "name") as? String, "Facebook")

        dropContainer(container)
    }

    func testCustomMappingAndCustomPrimaryKey() {
        let container = NSPersistentContainer(modelName: "Contacts")
        let objects = Helper.objectsFromJSON("images.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "Image", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let array = Helper.fetchEntity("Image", sortDescriptors: [NSSortDescriptor(key: "url", ascending: true)], inContext: container.viewContext)
        XCTAssertEqual(array.count, 3)
        let image = array.first
        XCTAssertEqual(image!.value(forKey: "url") as? String, "http://sample.com/sample0.png")

        dropContainer(container)
    }

    func testRelationshipsB() {
        let container = NSPersistentContainer(modelName: "Contacts")

        let objects = Helper.objectsFromJSON("users_c.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 4)

        let users = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 6)), inContext: container.viewContext)
        let user = users.first!
        XCTAssertEqual(user.value(forKey: "name") as? String, "Shawn Merrill")

        let location = user.value(forKey: "location") as! NSManagedObject
        XCTAssertEqual(location.value(forKey: "city") as? String, "New York")
        XCTAssertEqual(location.value(forKey: "street") as? String, "Broadway")
        XCTAssertEqual(location.value(forKey: "zipCode") as? NSNumber, NSNumber(value: 10012))

        let profilePicturesCount = Helper.countForEntity("Image", predicate: NSPredicate(format: "user = %@", user), inContext: container.viewContext)
        XCTAssertEqual(profilePicturesCount, 3)

        dropContainer(container)
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try only inserting user, no update, no insert, so the second sync should leave us with
    // 2 users with no changes and 1 inserted user.
    func testSyncingWithOnlyInsertOperationType() {
        let container = NSPersistentContainer(modelName: "Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsB, inEntityNamed: "User", operations: [.insert], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "melisawhite@ovium.com")

        dropContainer(container)
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try only inserting user, no update, no insert, so the second sync should leave us with
    // 2 users with no changes and 1 inserted user. After this is done, we'll try inserting again, this shouldn't make any changes.
    func testSyncingWithMultipleInsertOperationTypes() {
        let container = NSPersistentContainer(modelName: "Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsB, inEntityNamed: "User", operations: [.insert], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "melisawhite@ovium.com")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsB, inEntityNamed: "User", operations: [.insert], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)

        dropContainer(container)
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try only updating users, no insert, no delete, so the second sync should leave us with
    // one updated user and one inserted user, the third user will be discarded.
    func testSyncingWithOnlyUpdateOperationType() {
        let container = NSPersistentContainer(modelName: "Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsB, inEntityNamed: "User", operations: [.update], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "updated@ovium.com")

        dropContainer(container)
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try only deleting users, no insert, no update, so the second sync should leave us with
    // one inserted user, one deleted user and one discarded user.
    func testSyncingWithOnlyDeleteOperationType() {
        let container = NSPersistentContainer(modelName: "Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsB, inEntityNamed: "User", operations: [.delete], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "melisawhite@ovium.com")

        dropContainer(container)
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try inserting and updating users, no delete, so the second sync should leave us with
    // one updated user, one inserted user, and one user with no changes.
    func testSyncingWithInsertAndUpdateOperationType() {
        let container = NSPersistentContainer(modelName: "Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objectsB, inEntityNamed: "User", operations: [.insert, .update], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)

        let user0 = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertEqual(user0.value(forKey: "email") as? String, "updated@ovium.com")

        let user1 = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 1)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: container.viewContext).first!
        XCTAssertNotNil(user1)

        dropContainer(container)
    }

    // MARK: - Notes

    func testRelationshipsA() {
        let objects = Helper.objectsFromJSON("users_notes.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Notes")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "SuperUser", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("SuperUser", inContext: container.viewContext), 4)
        let users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 6)), inContext: container.viewContext)
        let user = users.first!
        XCTAssertEqual(user.value(forKey: "name") as? String, "Shawn Merrill")

        let notesCount = Helper.countForEntity("SuperNote", predicate: NSPredicate(format: "superUser = %@", user), inContext: container.viewContext)
        XCTAssertEqual(notesCount, 5)

        dropContainer(container)
    }

    func testObjectsForParent() {
        let objects = Helper.objectsFromJSON("notes_for_user_a.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "InsertObjectsInParent")
        
        backExpectation = expectation(description: "Background Context")
        container.performBackgroundTask { [weak self] backgroundContext in
            // First, we create a parent user, this user is the one that will own all the notes
            let user = NSEntityDescription.insertNewObject(forEntityName: "SuperUser", into: backgroundContext)
            user.setValue(NSNumber(value: 6), forKey: "remoteID")

            try! backgroundContext.save()
            self?.backCompletion()
        }
        waitForExpectations(timeout: 2)

        // Then we fetch the user on the main context, because we don't want to break things between contexts
        var users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 6)), inContext: container.viewContext)
        XCTAssertEqual(users.count, 1)

        // Finally we say "Sync all the notes, for this user"
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "SuperNote", parent: users.first!, completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        // Here we just make sure that the user has the notes that we just inserted
        users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 6)), inContext: container.viewContext)
        let user = users.first!
        XCTAssertEqual(user.value(forKey: "remoteID") as? NSNumber, NSNumber(value: 6))

        let notesCount = Helper.countForEntity("SuperNote", predicate: NSPredicate(format: "superUser = %@", user), inContext: container.viewContext)
        XCTAssertEqual(notesCount, 2)

        dropContainer(container)
    }

    func testTaggedNotesForUser() {
        let objects = Helper.objectsFromJSON("tagged_notes.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Notes")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "SuperNote", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("SuperNote", inContext: container.viewContext), 3)
        let notes = Helper.fetchEntity("SuperNote", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: container.viewContext)
        let note = notes.first!
        XCTAssertEqual((note.value(forKey: "superTags") as? NSSet)!.allObjects.count, 2)

        XCTAssertEqual(Helper.countForEntity("SuperTag", inContext: container.viewContext), 2)
        let tags = Helper.fetchEntity("SuperTag", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 1)), inContext: container.viewContext)
        XCTAssertEqual(tags.count, 1)

        let tag = tags.first!
        XCTAssertEqual((tag.value(forKey: "superNotes") as? NSSet)!.allObjects.count, 2)
        dropContainer(container)
    }

    func testCustomKeysInRelationshipsToMany() {
        let objects = Helper.objectsFromJSON("custom_relationship_key_to_many.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "CustomRelationshipKey")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let array = Helper.fetchEntity("User", inContext: container.viewContext)
        let user = array.first!
        XCTAssertEqual((user.value(forKey: "notes") as? NSSet)!.allObjects.count, 3)

        dropContainer(container)
    }

    // MARK: - Recursive

    func testNumbersWithEmptyRelationship() {
        let objects = Helper.objectsFromJSON("numbers.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Recursive")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "Number", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Number", inContext: container.viewContext), 6)

        dropContainer(container)
    }

    func testRelationshipName() {
        let objects = Helper.objectsFromJSON("numbers_in_collection.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Recursive")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "Number", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Collection", inContext: container.viewContext), 1)

        let numbers = Helper.fetchEntity("Number", inContext: container.viewContext)
        let number = numbers.first!
        XCTAssertNotNil(number.value(forKey: "parent"))
        XCTAssertEqual((number.value(forKey: "parent") as! NSManagedObject).value(forKey: "name") as? String, "Collection 1")

        dropContainer(container)
    }

    // MARK: - Social

    func testCustomPrimaryKey() {
        let objects = Helper.objectsFromJSON("comments-no-id.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Social")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "SocialComment", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("SocialComment", inContext: container.viewContext), 8)
        let comments = Helper.fetchEntity("SocialComment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: container.viewContext)
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual((comments.first!.value(forKey: "comments") as! NSSet).count, 3)

        let comment = comments.first!
        XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")

        dropContainer(container)
    }

    func testCustomPrimaryKeyInsideToManyRelationship() {
        let objects = Helper.objectsFromJSON("stories-comments-no-ids.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Social")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "Story", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Story", inContext: container.viewContext), 3)
        let stories = Helper.fetchEntity("Story", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: container.viewContext)
        let story = stories.first!

        XCTAssertEqual((story.value(forKey: "comments") as! NSSet).count, 3)

        XCTAssertEqual(Helper.countForEntity("SocialComment", inContext: container.viewContext), 9)
        var comments = Helper.fetchEntity("SocialComment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: container.viewContext)
        XCTAssertEqual(comments.count, 1)

        comments = Helper.fetchEntity("SocialComment", predicate: NSPredicate(format: "body = %@ AND story = %@", "comment 1", story), inContext: container.viewContext)
        XCTAssertEqual(comments.count, 1)
        if let comment = comments.first {
            XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")
            XCTAssertEqual((comment.value(forKey: "story") as? NSManagedObject)!.value(forKey: "remoteID") as? NSNumber, NSNumber(value: 0))
            XCTAssertEqual((comment.value(forKey: "story") as? NSManagedObject)!.value(forKey: "title") as? String, "story 1")
        } else {
            XCTFail()
        }

        dropContainer(container)
    }

    func testCustomKeysInRelationshipsToOne() {
        let objects = Helper.objectsFromJSON("custom_relationship_key_to_one.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Social")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "Story", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let array = Helper.fetchEntity("Story", inContext: container.viewContext)
        let story = array.first!
        XCTAssertNotNil(story.value(forKey: "summarize"))

        dropContainer(container)
    }

    // MARK: - Markets

    func testMarketsAndItems() {
        let objects = Helper.objectsFromJSON("markets_items.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Markets")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "Market", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Market", inContext: container.viewContext), 2)
        let markets = Helper.fetchEntity("Market", predicate: NSPredicate(format: "uniqueId = %@", "1"), inContext: container.viewContext)
        let market = markets.first!
        XCTAssertEqual(market.value(forKey: "otherAttribute") as? String, "Market 1")
        XCTAssertEqual((market.value(forKey: "items") as? NSSet)!.allObjects.count, 1)

        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 1)
        let items = Helper.fetchEntity("Item", predicate: NSPredicate(format: "uniqueId = %@", "1"), inContext: container.viewContext)
        let item = items.first!
        XCTAssertEqual(item.value(forKey: "otherAttribute") as? String, "Item 1")
        XCTAssertEqual((item.value(forKey: "markets") as? NSSet)!.allObjects.count, 2)

        dropContainer(container)
    }

    // MARK: - Organization

    func testOrganization() {
        let json = Helper.objectsFromJSON("organizations-tree.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Organizations")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(json, inEntityNamed: "OrganizationUnit", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("OrganizationUnit", inContext: container.viewContext), 7)

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(json, inEntityNamed: "OrganizationUnit", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("OrganizationUnit", inContext: container.viewContext), 7)

        dropContainer(container)
    }

    // MARK: - Unique

    /**
     *  C and A share the same collection of B, so in the first block
     *  2 entries of B get stored in A, in the second block this
     *  2 entries of B get updated and one entry of C gets added.
     */
    func testUniqueObject() {
        let objects = Helper.objectsFromJSON("unique.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Unique")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "A", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("A", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("B", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("C", inContext: container.viewContext), 0)

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "C", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("A", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("B", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("C", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // MARK: - Patients => https://github.com/3lvis/Sync/issues/121

    func testPatients() {
        let objects = Helper.objectsFromJSON("patients.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Patients")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "Patient", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Patient", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Baseline", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Alcohol", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Fitness", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Weight", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Measure", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // MARK: - Bug 84 => https://github.com/3lvis/Sync/issues/84

    func testStaffAndfulfillers() {
        let objects = Helper.objectsFromJSON("bug-number-84.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "84")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "MSStaff", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("MSStaff", inContext: container.viewContext), 1)

        let staff = Helper.fetchEntity("MSStaff", predicate: NSPredicate(format: "xid = %@", "mstaff_F58dVBTsXznvMpCPmpQgyV"), inContext: container.viewContext)
        let oneStaff = staff.first!
        XCTAssertEqual(oneStaff.value(forKey: "image") as? String, "a.jpg")
        XCTAssertEqual((oneStaff.value(forKey: "fulfillers") as? NSSet)!.allObjects.count, 2)

        let numberOffulfillers = Helper.countForEntity("MSFulfiller", inContext: container.viewContext)
        XCTAssertEqual(numberOffulfillers, 2)

        let fulfillers = Helper.fetchEntity("MSFulfiller", predicate: NSPredicate(format: "xid = %@", "ffr_AkAHQegYkrobp5xc2ySc5D"), inContext: container.viewContext)
        let fullfiller = fulfillers.first!
        XCTAssertEqual(fullfiller.value(forKey: "name") as? String, "New York")
        XCTAssertEqual((fullfiller.value(forKey: "staff") as? NSSet)!.allObjects.count, 1)

        dropContainer(container)
    }

    // MARK: - Bug 113 => https://github.com/3lvis/Sync/issues/113

    func testCustomPrimaryKeyBug113() {
        let objects = Helper.objectsFromJSON("bug-113-comments-no-id.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "113")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "AwesomeComment", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("AwesomeComment", inContext: container.viewContext), 8)
        let comments = Helper.fetchEntity("AwesomeComment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: container.viewContext)
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual((comments.first!.value(forKey: "awesomeComments") as! NSSet).count, 3)

        let comment = comments.first!
        XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")

        dropContainer(container)
    }

    func testCustomPrimaryKeyInsideToManyRelationshipBug113() {
        let objects = Helper.objectsFromJSON("bug-113-stories-comments-no-ids.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "113")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "AwesomeStory", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("AwesomeStory", inContext: container.viewContext), 3)
        let stories = Helper.fetchEntity("AwesomeStory", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: container.viewContext)
        let story = stories.first!
        XCTAssertEqual((story.value(forKey: "awesomeComments") as! NSSet).count, 3)

        XCTAssertEqual(Helper.countForEntity("AwesomeComment", inContext: container.viewContext), 9)
        var comments = Helper.fetchEntity("AwesomeComment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: container.viewContext)
        XCTAssertEqual(comments.count, 1)

        comments = Helper.fetchEntity("AwesomeComment", predicate: NSPredicate(format: "body = %@ AND awesomeStory = %@", "comment 1", story), inContext: container.viewContext)
        XCTAssertEqual(comments.count, 1)
        if let comment = comments.first {
            XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")
            let awesomeStory = comment.value(forKey: "awesomeStory") as! NSManagedObject
            XCTAssertEqual(awesomeStory.value(forKey: "remoteID") as? NSNumber, NSNumber(value: 0))
            XCTAssertEqual(awesomeStory.value(forKey: "title") as? String, "story 1")
        } else {
            XCTFail()
        }

        dropContainer(container)
    }

    func testCustomKeysInRelationshipsToOneBug113() {
        let objects = Helper.objectsFromJSON("bug-113-custom_relationship_key_to_one.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "113")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "AwesomeStory", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let array = Helper.fetchEntity("AwesomeStory", inContext: container.viewContext)
        let story = array.first!
        XCTAssertNotNil(story.value(forKey: "awesomeSummarize"))

        dropContainer(container)
    }

    // MARK: - Bug 125 => https://github.com/3lvis/Sync/issues/125

    func testNilRelationshipsAfterUpdating_Sync_1_0_10() {
        let formDictionary = Helper.objectsFromJSON("bug-125.json") as! [String: Any]
        let uri = formDictionary["uri"] as! String
        let container = NSPersistentContainer(modelName: "125")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync([formDictionary], inEntityNamed: "Form", predicate: NSPredicate(format: "uri == %@", uri), completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Form", inContext: container.viewContext), 1)

        XCTAssertEqual(Helper.countForEntity("Element", inContext: container.viewContext), 11)

        XCTAssertEqual(Helper.countForEntity("SelectionItem", inContext: container.viewContext), 4)

        XCTAssertEqual(Helper.countForEntity("Model", inContext: container.viewContext), 1)

        XCTAssertEqual(Helper.countForEntity("ModelProperty", inContext: container.viewContext), 9)

        XCTAssertEqual(Helper.countForEntity("Restriction", inContext: container.viewContext), 3)

        let array = Helper.fetchEntity("Form", inContext: container.viewContext)
        let form = array.first!
        let element = form.value(forKey: "element") as! NSManagedObject
        let model = form.value(forKey: "model") as! NSManagedObject
        XCTAssertNotNil(element)
        XCTAssertNotNil(model)

        dropContainer(container)
    }

    func testStoryToSummarize() {
        let formDictionary = Helper.objectsFromJSON("story-summarize.json") as! [String: Any]
        let container = NSPersistentContainer(modelName: "Social")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync([formDictionary], inEntityNamed: "Story", predicate: NSPredicate(format: "remoteID == %@", NSNumber(value: 1)), completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Story", inContext: container.viewContext), 1)
        let stories = Helper.fetchEntity("Story", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 1)), inContext: container.viewContext)
        let story = stories.first!
        let summarize = story.value(forKey: "summarize") as! NSManagedObject
        XCTAssertEqual(summarize.value(forKey: "remoteID") as? NSNumber, NSNumber(value: 1))
        XCTAssertEqual((story.value(forKey: "comments") as! NSSet).count, 1)

        XCTAssertEqual(Helper.countForEntity("SocialComment", inContext: container.viewContext), 1)
        let comments = Helper.fetchEntity("SocialComment", predicate: NSPredicate(format: "body = %@", "Hi"), inContext: container.viewContext)
        XCTAssertEqual(comments.count, 1)

        dropContainer(container)
    }

    /**
     * When having JSONs like this:
     * {
     *   "id":12345,
     *    "name":"My Project",
     *    "category_id":12345
     * }
     * It will should map category_id with the necesary category object using the ID 12345
     */
    func testIDRelationshipMapping() {
        let usersDictionary = Helper.objectsFromJSON("users_a.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "Notes")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersDictionary, inEntityNamed: "SuperUser", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let usersCount = Helper.countForEntity("SuperUser", inContext: container.viewContext)
        XCTAssertEqual(usersCount, 8)

        let notesDictionary = Helper.objectsFromJSON("notes_with_user_id.json") as! [[String: Any]]

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(notesDictionary, inEntityNamed: "SuperNote", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let notesCount = Helper.countForEntity("SuperNote", inContext: container.viewContext)
        XCTAssertEqual(notesCount, 5)

        let notes = Helper.fetchEntity("SuperNote", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: container.viewContext)
        let note = notes.first!
        let user = note.value(forKey: "superUser")!
        XCTAssertEqual((user as AnyObject).value(forKey: "name") as? String, "Melisa White")

        dropContainer(container)
    }

    /**
     * When having JSONs like this:
     * {
     *   "id":12345,
     *    "name":"My Project",
     *    "category":12345
     * }
     * It will should map category_id with the necesary category object using the ID 12345, but adding a custom remoteKey would make it map to category with ID 12345
     */
    func testIDRelationshipCustomMapping() {
        let usersDictionary = Helper.objectsFromJSON("users_a.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "NotesB")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersDictionary, inEntityNamed: "SuperUserB", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let usersCount = Helper.countForEntity("SuperUserB", inContext: container.viewContext)
        XCTAssertEqual(usersCount, 8)

        let notesDictionary = Helper.objectsFromJSON("notes_with_user_id_custom.json") as! [[String: Any]]

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(notesDictionary, inEntityNamed: "SuperNoteB", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let notesCount = Helper.countForEntity("SuperNoteB", inContext: container.viewContext)
        XCTAssertEqual(notesCount, 5)

        let notes = Helper.fetchEntity("SuperNoteB", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: container.viewContext)
        let note = notes.first!
        let user = note.value(forKey: "superUser")!
        XCTAssertEqual((user as AnyObject).value(forKey: "name") as? String, "Melisa White")

        dropContainer(container)
    }

    // MARK: - Ordered Social

    func testCustomPrimaryKeyInOrderedRelationship() {
        let objects = Helper.objectsFromJSON("comments-no-id.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "OrderedSocial")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(objects, inEntityNamed: "Comment", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Comment", inContext: container.viewContext), 8)
        let comments = Helper.fetchEntity("Comment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: container.viewContext)
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual((comments.first!.value(forKey: "comments") as! NSOrderedSet).count, 3)

        let comment = comments.first!
        XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")

        dropContainer(container)
    }

    // MARK: - Bug 179 => https://github.com/3lvis/Sync/issues/179

    func testConnectMultipleRelationships() {
        let places = Helper.objectsFromJSON("bug-179-places.json") as! [[String: Any]]
        let routes = Helper.objectsFromJSON("bug-179-routes.json") as! [String: Any]
        let container = NSPersistentContainer(modelName: "179")

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(places, inEntityNamed: "Place", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync([routes], inEntityNamed: "Route", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Route", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Place", inContext: container.viewContext), 2)
        let importedRoutes = Helper.fetchEntity("Route", predicate: nil, inContext: container.viewContext)
        XCTAssertEqual(importedRoutes.count, 1)
        let importedRouter = importedRoutes.first!
        XCTAssertEqual(importedRouter.value(forKey: "ident") as? String, "1")

        let startPlace = importedRoutes.first!.value(forKey: "startPlace") as! NSManagedObject
        let endPlace = importedRoutes.first!.value(forKey: "endPlace") as! NSManagedObject
        XCTAssertEqual(startPlace.value(forKey: "name") as? String, "Here")
        XCTAssertEqual(endPlace.value(forKey: "name") as? String, "There")

        dropContainer(container)
    }

    // MARK: - Bug 202 => https://github.com/3lvis/Sync/issues/202

    func testManyToManyKeyNotAllowedHere() {
        let container = NSPersistentContainer(modelName: "202")

        let initialInsert = Helper.objectsFromJSON("bug-202-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initialInsert, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        let removeAll = Helper.objectsFromJSON("bug-202-b.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(removeAll, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // MARK: - Automatic use of id as remoteID

    func testIDAsRemoteID() {
        let container = NSPersistentContainer(modelName: "id")

        let users = Helper.objectsFromJSON("id.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(users, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)

        dropContainer(container)
    }

    // MARK: - Bug 157 => https://github.com/3lvis/Sync/issues/157

    func testBug157() {
        let container = NSPersistentContainer(modelName: "157")

        // 3 locations get synced, their references get ignored since no cities are found
        let locations = Helper.objectsFromJSON("157-locations.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(locations, inEntityNamed: "Location", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Location", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("City", inContext: container.viewContext), 0)

        // 3 cities get synced
        let cities = Helper.objectsFromJSON("157-cities.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(cities, inEntityNamed: "City", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Location", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("City", inContext: container.viewContext), 3)

        // 3 locations get synced, but now since their references are available the relationships get made
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(locations, inEntityNamed: "Location", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        var location1 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 0"), inContext: container.viewContext).first
        var location1City = location1?.value(forKey: "city") as? NSManagedObject
        XCTAssertEqual(location1City?.value(forKey: "name") as? String, "Oslo")
        var location2 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 1"), inContext: container.viewContext).first
        var location2City = location2?.value(forKey: "city") as? NSManagedObject
        XCTAssertEqual(location2City?.value(forKey: "name") as? String, "Paris")
        var location3 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 2"), inContext: container.viewContext).first
        var location3City = location3?.value(forKey: "city") as? NSManagedObject
        XCTAssertNil(location3City?.value(forKey: "name") as? String)

        // Finally we update the relationships to test changing relationships
        let updatedLocations = Helper.objectsFromJSON("157-locations-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updatedLocations, inEntityNamed: "Location", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        
        location1 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 0"), inContext: container.viewContext).first
        location1City = location1?.value(forKey: "city") as? NSManagedObject
        XCTAssertNil(location1City?.value(forKey: "name") as? String)
        
        location2 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 1"), inContext: container.viewContext).first
        location2City = location2?.value(forKey: "city") as? NSManagedObject
        XCTAssertEqual(location2City?.value(forKey: "name") as? String, "Oslo")
        
        location3 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 2"), inContext: container.viewContext).first
        location3City = location3?.value(forKey: "city") as? NSManagedObject
        XCTAssertEqual(location3City?.value(forKey: "name") as? String, "Paris")

        dropContainer(container)
    }

    // MARK: - Add support for cancellable sync processes https://github.com/3lvis/Sync/pull/216

    func testOperation() {
        let container = NSPersistentContainer(modelName: "id")

        let users = Helper.objectsFromJSON("id.json") as! [[String: Any]]
        let operation = Sync(changes: users, inEntityNamed: "User", predicate: nil, persistentContainer: container)
        
        let expectation = expectation(description: "Wait end")
        operation.start {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)

        dropContainer(container)
    }

    // MARK: - Support multiple ids to set a relationship (to-many) => https://github.com/3lvis/Sync/issues/151
    // Notes have to be unique, two users can't have the same note.

    func testMultipleIDRelationshipToMany() {
        let container = NSPersistentContainer(modelName: "151-to-many")

        // Inserts 3 users, it ignores the relationships since no notes are found
        let users = Helper.objectsFromJSON("151-to-many-users.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(users, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 0)

        // Inserts 3 notes
        let notes = Helper.objectsFromJSON("151-to-many-notes.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(notes, inEntityNamed: "Note", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 3)
        let savedUsers = Helper.fetchEntity("User", inContext: container.viewContext)
        var total = 0
        for user in savedUsers {
            let notes = user.value(forKey: "notes") as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            total += notes.count
        }
        XCTAssertEqual(total, 0)

        // Updates the first 3 users, but now it makes the relationships with the notes
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(users, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 3)
        var user10 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 10"), inContext: container.viewContext).first
        var user10Notes = user10?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user10Notes?.count, 2)
        var user11 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 11"), inContext: container.viewContext).first
        var user11Notes = user11?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user11Notes?.count, 1)
        var user12 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 12"), inContext: container.viewContext).first
        var user12Notes = user12?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user12Notes?.count, 0)
        var note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 0"), inContext: container.viewContext).first
        var note0User = note0?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note0User?.value(forKey: "userID") as? Int, 10)
        var note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 1"), inContext: container.viewContext).first
        var note1User = note1?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note1User?.value(forKey: "userID") as? Int, 10)
        var note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 2"), inContext: container.viewContext).first
        var note2User = note2?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note2User?.value(forKey: "userID") as? Int, 11)

        // Updates the first 3 users again, but now it changes all the relationships
        let updatedUsers = Helper.objectsFromJSON("151-to-many-users-update.json") as! [[String: Any]]
        
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updatedUsers, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 3)
        user10 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 10"), inContext: container.viewContext).first
        user10Notes = user10?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user10Notes?.count, 0)
        user11 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 11"), inContext: container.viewContext).first
        user11Notes = user11?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user11Notes?.count, 1)
        user12 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 12"), inContext: container.viewContext).first
        user12Notes = user12?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user12Notes?.count, 2)
        note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 0"), inContext: container.viewContext).first
        note0User = note0?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note0User?.value(forKey: "userID") as? Int, 12)
        note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 1"), inContext: container.viewContext).first
        note1User = note1?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note1User?.value(forKey: "userID") as? Int, 12)
        note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 2"), inContext: container.viewContext).first
        note2User = note2?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note2User?.value(forKey: "userID") as? Int, 11)

        dropContainer(container)
    }

    // MARK: - Support multiple ids to set a relationship (to-many) => https://github.com/3lvis/Sync/issues/151
    // Notes have to be unique, two users can't have the same note.

    func testOrderedMultipleIDRelationshipToMany() {
        let container = NSPersistentContainer(modelName: "151-ordered-to-many")

        // Inserts 3 users, it ignores the relationships since no notes are found
        let users = Helper.objectsFromJSON("151-to-many-users.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(users, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 0)

        // Inserts 3 notes
        let notes = Helper.objectsFromJSON("151-to-many-notes.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(notes, inEntityNamed: "Note", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 3)
        let savedUsers = Helper.fetchEntity("User", inContext: container.viewContext)
        var total = 0
        for user in savedUsers {
            let notes = user.value(forKey: "notes") as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            total += notes.count
        }
        XCTAssertEqual(total, 0)

        // Updates the first 3 users, but now it makes the relationships with the notes
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(users, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 3)
        var user10 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 10"), inContext: container.viewContext).first
        var user10Notes = user10?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user10Notes?.set.count, 2)
        var user11 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 11"), inContext: container.viewContext).first
        var user11Notes = user11?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user11Notes?.set.count, 1)
        var user12 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 12"), inContext: container.viewContext).first
        var user12Notes = user12?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user12Notes?.set.count, 0)

        // Updates the first 3 users again, but now it changes all the relationships
        let updatedUsers = Helper.objectsFromJSON("151-to-many-users-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updatedUsers, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 3)
        user10 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 10"), inContext: container.viewContext).first
        user10Notes = user10?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user10Notes?.set.count, 0)
        user11 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 11"), inContext: container.viewContext).first
        user11Notes = user11?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user11Notes?.set.count, 1)
        user12 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 12"), inContext: container.viewContext).first
        user12Notes = user12?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user12Notes?.set.count, 2)

        dropContainer(container)
    }

    // MARK: - Support multiple ids to set a relationship (many-to-many) => https://github.com/3lvis/Sync/issues/151

    func testMultipleIDRelationshipManyToMany() {
        let container = NSPersistentContainer(modelName: "151-many-to-many")

        // Inserts 4 notes
        let notes = Helper.objectsFromJSON("151-many-to-many-notes.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(notes, inEntityNamed: "Note", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 0)

        // Inserts 3 tags
        let tags = Helper.objectsFromJSON("151-many-to-many-tags.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(tags, inEntityNamed: "Tag", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 2)
        let savedNotes = Helper.fetchEntity("Note", inContext: container.viewContext)
        var total = 0
        for note in savedNotes {
            let tags = note.value(forKey: "tags") as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            total += tags.count
        }
        XCTAssertEqual(total, 0)

        // Updates the first 4 notes, but now it makes the relationships with the tags
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(notes, inEntityNamed: "Note", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 2)
        var note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 0"), inContext: container.viewContext).first
        var note0Tags = note0?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note0Tags?.count, 2)
        var note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 1"), inContext: container.viewContext).first
        var note1Tags = note1?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note1Tags?.count, 1)
        var note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 2"), inContext: container.viewContext).first
        var note2Tags = note2?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note2Tags?.count, 0)
        var note3 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 3"), inContext: container.viewContext).first
        var note3Tags = note3?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note3Tags?.count, 1)

        // Updates the first 4 notes again, but now it changes all the relationships
        let updatedNotes = Helper.objectsFromJSON("151-many-to-many-notes-update.json") as! [[String: Any]]
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 2)
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updatedNotes, inEntityNamed: "Note", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 0"), inContext: container.viewContext).first
        note0Tags = note0?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note0Tags?.count, 1)
        note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 1"), inContext: container.viewContext).first
        note1Tags = note1?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note1Tags?.count, 0)
        note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 2"), inContext: container.viewContext).first
        note2Tags = note2?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note2Tags?.count, 2)
        note3 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 3"), inContext: container.viewContext).first
        note3Tags = note3?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note3Tags?.count, 0)

        dropContainer(container)
    }

    // MARK: - Support multiple ids to set a relationship (many-to-many) => https://github.com/3lvis/Sync/issues/151

    func testOrderedMultipleIDRelationshipManyToMany() {
        let container = NSPersistentContainer(modelName: "151-ordered-many-to-many")

        // Inserts 4 notes
        let notes = Helper.objectsFromJSON("151-many-to-many-notes.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(notes, inEntityNamed: "Note", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 0)

        // Inserts 3 tags
        let tags = Helper.objectsFromJSON("151-many-to-many-tags.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(tags, inEntityNamed: "Tag", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 2)
        let savedNotes = Helper.fetchEntity("Note", inContext: container.viewContext)
        var total = 0
        for note in savedNotes {
            let tags = note.value(forKey: "tags") as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            total += tags.count
        }
        XCTAssertEqual(total, 0)

        // Updates the first 4 notes, but now it makes the relationships with the tags
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(notes, inEntityNamed: "Note", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 2)
        var note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 0"), inContext: container.viewContext).first
        var note0Tags = note0?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note0Tags?.count, 2)
        var note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 1"), inContext: container.viewContext).first
        var note1Tags = note1?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note1Tags?.count, 1)
        var note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 2"), inContext: container.viewContext).first
        var note2Tags = note2?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note2Tags?.count, 0)
        var note3 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 3"), inContext: container.viewContext).first
        var note3Tags = note3?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note3Tags?.count, 1)

        // Updates the first 4 notes again, but now it changes all the relationships
        let updatedNotes = Helper.objectsFromJSON("151-many-to-many-notes-update.json") as! [[String: Any]]
        XCTAssertEqual(Helper.countForEntity("Note", inContext: container.viewContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 2)
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updatedNotes, inEntityNamed: "Note", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 0"), inContext: container.viewContext).first
        note0Tags = note0?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note0Tags?.set.count, 1)
        note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 1"), inContext: container.viewContext).first
        note1Tags = note1?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note1Tags?.set.count, 0)
        note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 2"), inContext: container.viewContext).first
        note2Tags = note2?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note2Tags?.set.count, 2)
        note3 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 3"), inContext: container.viewContext).first
        note3Tags = note3?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note3Tags?.count, 0)

        dropContainer(container)
    }

    // MARK: - Bug 257 => https://github.com/3lvis/Sync/issues/257

    func testBug257() {
        let container = NSPersistentContainer(modelName: "257")

        let JSON = Helper.objectsFromJSON("bug-257.json") as! [String: Any]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync([JSON], inEntityNamed: "Workout", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Workout", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Exercise", inContext: container.viewContext), 2)

        dropContainer(container)
    }

    // MARK: - Bug 254 => https://github.com/3lvis/Sync/issues/254

    func testBug254() {
        let container = NSPersistentContainer(modelName: "254")

        let JSON = Helper.objectsFromJSON("bug-254.json") as! [String: Any]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync([JSON], inEntityNamed: "House", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("House", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Human", inContext: container.viewContext), 1)

        // Verify correct "House -> Resident" connections
        let house = Helper.fetchEntity("House", predicate: NSPredicate(format: "id = 0"), inContext: container.viewContext).first
        let residents = house?.value(forKey: "residents") as? Set<NSManagedObject>
        let resident = residents?.first
        XCTAssertEqual(resident?.value(forKey: "id") as? Int, 0)

        let residentHouse = resident?.value(forKey: "residenthouse") as? NSManagedObject
        XCTAssertEqual(residentHouse?.value(forKey: "id") as? Int, 0)

        // Verify empty "Ownhouses -> Owners" connections
        let human = Helper.fetchEntity("Human", predicate: NSPredicate(format: "id = 0"), inContext: container.viewContext).first
        let ownhouses = human?.value(forKey: "ownhouses") as? Set<NSManagedObject>
        XCTAssertEqual(ownhouses?.count, 0)

        dropContainer(container)
    }

    // MARK: Bug 260 => https://github.com/3lvis/Sync/issues/260

    func testBug260CamelCase() {
        let container = NSPersistentContainer(modelName: "ToOne")

        let snakeCaseJSON = Helper.objectsFromJSON("to-one-snakecase.json") as! [String: Any]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync([snakeCaseJSON], inEntityNamed: "RentedHome", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("RentedHome", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("LegalPerson", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    func testBug260SnakeCase() {
        let container = NSPersistentContainer(modelName: "ToOne")

        let camelCaseJSON = Helper.objectsFromJSON("to-one-camelcase.json") as! [String: Any]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync([camelCaseJSON], inEntityNamed: "RentedHome", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("RentedHome", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("LegalPerson", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // MARK: Bug 239 => https://github.com/3lvis/Sync/pull/239

    func testBug239() {
        let carsObject = Helper.objectsFromJSON("bug-239.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "239")
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(carsObject, inEntityNamed: "Racecar", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Racecar", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Passenger", inContext: container.viewContext), 2)

        let racecars = Helper.fetchEntity("Racecar", predicate: nil, inContext: container.viewContext)
        let racecar = racecars.first!
        XCTAssertEqual((racecar.value(forKey: "passengers") as? NSSet)!.allObjects.count, 2)

        dropContainer(container)
    }

    // MARK: - https://github.com/3lvis/Sync/issues/225

    func test225ReplacedTag() {
        let container = NSPersistentContainer(modelName: "225")

        let usersA = Helper.objectsFromJSON("225-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        // This should remove the old tag reference to the user and insert this new one.
        let usersB = Helper.objectsFromJSON("225-a-replaced.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersB, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 2)

        let user = Helper.fetchEntity("User", inContext: container.viewContext).first!
        let predicate = NSPredicate(format: "ANY users IN %@", [user])
        let tags = Helper.fetchEntity("Tag", predicate: predicate, inContext: container.viewContext)
        XCTAssertEqual(tags.count, 1)

        dropContainer(container)
    }

    func test225RemovedTagsWithEmptyArray() {
        let container = NSPersistentContainer(modelName: "225")

        let usersA = Helper.objectsFromJSON("225-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        // This should remove all the references.
        let usersB = Helper.objectsFromJSON("225-a-empty.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersB, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        let user = Helper.fetchEntity("User", inContext: container.viewContext).first!
        let predicate = NSPredicate(format: "ANY users IN %@", [user])
        let tags = Helper.fetchEntity("Tag", predicate: predicate, inContext: container.viewContext)
        XCTAssertEqual(tags.count, 0)

        dropContainer(container)
    }

    func test225RemovedTagsWithNull() {
        let container = NSPersistentContainer(modelName: "225")

        let usersA = Helper.objectsFromJSON("225-a.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        let usersB = Helper.objectsFromJSON("225-a-null.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersB, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        let user = Helper.fetchEntity("User", inContext: container.viewContext).first!
        let predicate = NSPredicate(format: "ANY users IN %@", [user])
        let tags = Helper.fetchEntity("Tag", predicate: predicate, inContext: container.viewContext)
        XCTAssertEqual(tags.count, 0)

        dropContainer(container)
    }

    func test280() {
        let container = NSPersistentContainer(modelName: "280")

        let routes = Helper.objectsFromJSON("280.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(routes, inEntityNamed: "Route", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Route", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("RoutePolylineItem", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("RouteStop", inContext: container.viewContext), 1)

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(routes, inEntityNamed: "Route", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Route", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("RoutePolylineItem", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("RouteStop", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    func test283() {
        let container = NSPersistentContainer(modelName: "283")

        let taskLists = Helper.objectsFromJSON("283.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(taskLists, inEntityNamed: "TaskList", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("TaskList", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Owner", inContext: container.viewContext), 1)

        let taskList = Helper.fetchEntity("TaskList", inContext: container.viewContext).first!
        let owner = taskList.value(forKey: "owner") as? NSManagedObject
        XCTAssertNotNil(owner)

        let participants = taskList.value(forKey: "participants") as? NSSet ?? NSSet()
        XCTAssertEqual(participants.count, 0)

        dropContainer(container)
    }

    func test320RemoveOneToToneWithNull() {
        let container = NSPersistentContainer(modelName: "320")

        let tagA = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: container.viewContext)
        tagA.setValue(10, forKey: "remoteID")

        let userA = NSEntityDescription.insertNewObject(forEntityName: "User", into: container.viewContext)
        userA.setValue(1, forKey: "remoteID")
        userA.setValue(tagA, forKey: "tag")

        try! container.viewContext.save()

        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        let usersB = Helper.objectsFromJSON("320.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersB, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        let user = Helper.fetchEntity("User", inContext: container.viewContext).first!
        let predicate = NSPredicate(format: "ANY user = %@", user)
        let tag = Helper.fetchEntity("Tag", predicate: predicate, inContext: container.viewContext)
        XCTAssertEqual(tag.count, 0)

        dropContainer(container)
    }

    func test233() {
        let container = NSPersistentContainer(modelName: "233")

        let slide1 = NSEntityDescription.insertNewObject(forEntityName: "Slide", into: container.viewContext)
        slide1.setValue(1, forKey: "id")

        let slide2 = NSEntityDescription.insertNewObject(forEntityName: "Slide", into: container.viewContext)
        slide2.setValue(2, forKey: "id")

        let presentation = NSEntityDescription.insertNewObject(forEntityName: "Presentation", into: container.viewContext)
        presentation.setValue(1, forKey: "id")

        let slides = NSMutableOrderedSet()
        slides.add(slide1)
        slides.add(slide2)

        presentation.setValue(slides, forKey: "slides")

        try! container.viewContext.save()

        XCTAssertEqual(Helper.countForEntity("Presentation", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Slide", inContext: container.viewContext), 2)
        let lastSlide = Helper.fetchEntity("Presentation", inContext: container.viewContext).first!.mutableOrderedSetValue(forKey: "slides").lastObject as! NSManagedObject
        let lastSlideID = lastSlide.value(forKey: "id") as! Int
        XCTAssertEqual(lastSlideID, 2)

        // Change order of slides, before it was [1, 2], now it will be [2, 1]
        let presentationOrderB = Helper.objectsFromJSON("233.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(presentationOrderB, inEntityNamed: "Presentation", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Presentation", inContext: container.viewContext), 1)

        let firstSlide = Helper.fetchEntity("Presentation", inContext: container.viewContext).first!.mutableOrderedSetValue(forKey: "slides").firstObject as! NSManagedObject
        let firstSlideID = firstSlide.value(forKey: "id") as! Int

        // check if order is properly updated
        XCTAssertEqual(firstSlideID, lastSlideID)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/327

    func test327OrderedToMany() {
        let container = NSPersistentContainer(modelName: "233")

        let slide1 = NSEntityDescription.insertNewObject(forEntityName: "Slide", into: container.viewContext)
        slide1.setValue(1, forKey: "id")

        let slide2 = NSEntityDescription.insertNewObject(forEntityName: "Slide", into: container.viewContext)
        slide2.setValue(2, forKey: "id")

        let presentation = NSEntityDescription.insertNewObject(forEntityName: "Presentation", into: container.viewContext)
        presentation.setValue(1, forKey: "id")

        let slides = NSMutableOrderedSet()
        slides.add(slide1)
        slides.add(slide2)

        presentation.setValue(slides, forKey: "slides")

        try! container.viewContext.save()

        XCTAssertEqual(Helper.countForEntity("Presentation", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Slide", inContext: container.viewContext), 2)
        let lastSlide = Helper.fetchEntity("Presentation", inContext: container.viewContext).first!.mutableOrderedSetValue(forKey: "slides").lastObject as! NSManagedObject
        let lastSlideID = lastSlide.value(forKey: "id") as! Int
        XCTAssertEqual(lastSlideID, 2)

        // Change order of slides, before it was [1, 2], now it will be [2, 1]
        let presentationOrderB = Helper.objectsFromJSON("237.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(presentationOrderB, inEntityNamed: "Presentation", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Presentation", inContext: container.viewContext), 1)

        let firstSlide = Helper.fetchEntity("Presentation", inContext: container.viewContext).first!.mutableOrderedSetValue(forKey: "slides").firstObject as! NSManagedObject
        let firstSlideID = firstSlide.value(forKey: "id") as! Int

        // check if order is properly updated
        XCTAssertEqual(firstSlideID, lastSlideID)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/265

    func test265() {
        let container = NSPersistentContainer(modelName: "265")
        let players = Helper.objectsFromJSON("265.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(players, inEntityNamed: "Player", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        // Player 1
        // Has one player group: 1

        // Player group 1
        // This player group has two players: [1]

        // This should be 1, but sadly it's two :(
        XCTAssertEqual(Helper.countForEntity("Player", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("PlayerGroup", inContext: container.viewContext), 1)
        dropContainer(container)
    }

    func test3ca82a0() {
        let container = NSPersistentContainer(modelName: "3ca82a0")

        let taskLists = Helper.objectsFromJSON("3ca82a0.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(taskLists, inEntityNamed: "Article", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Article", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("ArticleTag", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // MARK: Bug 277 => https://github.com/3lvis/Sync/pull/277

    func test277() {
        let carsObject = Helper.objectsFromJSON("277.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "277")
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(carsObject, inEntityNamed: "Racecar", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Racecar", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("Passenger", inContext: container.viewContext), 1)

        var racecars = Helper.fetchEntity("Racecar", predicate: nil, inContext: container.viewContext)
        var racecar = racecars.first!
        XCTAssertEqual(racecar.value(forKey: "remoteID") as? Int, 31)
        XCTAssertEqual((racecar.value(forKey: "passengers") as? NSSet)!.allObjects.count, 1)

        racecars = Helper.fetchEntity("Racecar", predicate: nil, inContext: container.viewContext)
        racecar = racecars.last!
        XCTAssertEqual(racecar.value(forKey: "remoteID") as? Int, 32)
        XCTAssertEqual((racecar.value(forKey: "passengers") as? NSSet)!.allObjects.count, 1)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/375
    func test375() {
        let speeches = Helper.objectsFromJSON("375.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "375")
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(speeches, inEntityNamed: "Speech", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Speech", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Serie", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/375
    func test375toOne() {
        let speeches = Helper.objectsFromJSON("375-to-one.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "375-to-one")
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(speeches, inEntityNamed: "Speech", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Speech", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Serie", inContext: container.viewContext), 1)
        dropContainer(container)
    }

    func test375toManySimplified() {
        let series = Helper.objectsFromJSON("375-to-many-series.json") as! [[String: Any]]
        let speeches = Helper.objectsFromJSON("375-to-many-speeches.json") as! [[String: Any]]

        let container = NSPersistentContainer(modelName: "375")
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(series, inEntityNamed: "Serie", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Serie", inContext: container.viewContext), 1)

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(speeches, inEntityNamed: "Speech", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Speech", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Serie", inContext: container.viewContext), 1)
        let speech = Helper.fetchEntity("Speech", predicate: NSPredicate(format: "id = 4865"), inContext: container.viewContext).first
        let speechSeries = speech?.value(forKey: "series") as? Set<NSManagedObject>
        XCTAssertEqual(speechSeries?.count, 1)

        dropContainer(container)
    }

    func test375toOneSimplified() {
        let series = Helper.objectsFromJSON("375-to-many-series.json") as! [[String: Any]]
        let speeches = Helper.objectsFromJSON("375-to-one-speeches.json") as! [[String: Any]]

        let container = NSPersistentContainer(modelName: "375-to-one")
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(series, inEntityNamed: "Serie", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Serie", inContext: container.viewContext), 1)

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(speeches, inEntityNamed: "Speech", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Speech", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Serie", inContext: container.viewContext), 1)
        let speech = Helper.fetchEntity("Speech", predicate: NSPredicate(format: "id = 4865"), inContext: container.viewContext).first!
        let serie = speech.value(forKey: "serie")!
        XCTAssertEqual((serie as AnyObject).value(forKey: "id") as? Int, 123)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/pull/388
    func testRemoteKeyCompatibility() {
        let entititesJSON = Helper.objectsFromJSON("remote_key.json") as! [[String: Any]]
        let container = NSPersistentContainer(modelName: "RemoteKey")
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(entititesJSON, inEntityNamed: "Entity", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Entity", inContext: container.viewContext), 1)

        let entity = Helper.fetchEntity("Entity", inContext: container.viewContext).first!
        XCTAssertEqual(entity.value(forKey: "id") as? Int, 1)
        XCTAssertEqual(entity.value(forKey: "old") as? String, "old")
        XCTAssertEqual(entity.value(forKey: "current") as? String, "current")

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/417
    func test417() {
        let container = NSPersistentContainer(modelName: "225")

        let usersA = Helper.objectsFromJSON("417.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/373
    func test373() {
        let container = NSPersistentContainer(modelName: "225")

        let usersA = Helper.objectsFromJSON("373.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(usersA, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 2)

        let user3 = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = 3"), inContext: container.viewContext).first
        let user3Tags = user3?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(user3Tags?.count, 2)

        let user2 = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = 2"), inContext: container.viewContext).first
        let user2Tags = user2?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(user2Tags?.count, 1)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/412
    func test412() {
        let container = NSPersistentContainer(modelName: "412")

        let forms = Helper.objectsFromJSON("412.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(forms, inEntityNamed: "Form", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Form", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Field", inContext: container.viewContext), 0)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/447
    func testDoublePrimaryKeys() {
        let container = NSPersistentContainer(modelName: "DoublePrimaryKeys")

        let users = Helper.objectsFromJSON("primary-key-users.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(users, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Category", inContext: container.viewContext), 1)

        let organizations = Helper.objectsFromJSON("primary-key-organizations.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(organizations, inEntityNamed: "Organization", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Category", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("Organization", inContext: container.viewContext), 1)

        let organizations2 = Helper.objectsFromJSON("primary-key-organizations-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(organizations2, inEntityNamed: "Organization", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Category", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("Organization", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/447
    func test447() {
        let container = NSPersistentContainer(modelName: "447")

        let website = Helper.objectsFromJSON("447.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(website, inEntityNamed: "Website", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Website", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Category", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/457
    func test457() {
        let container = NSPersistentContainer(modelName: "457")
        let subcats = Helper.objectsFromJSON("457-subcategories.json") as! [[String: Any]]

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(subcats, inEntityNamed: "Subcategory", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(Helper.countForEntity("Subcategory", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Category", inContext: container.viewContext), 1)
        
        let products = Helper.objectsFromJSON("457-products.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(products, inEntityNamed: "Product", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        let result = Helper.fetchEntity("Product", inContext: container.viewContext)
        XCTAssertEqual(result.count, 1)
        let subcat = result.first?.value(forKey:"subcategory") as! NSManagedObject
        XCTAssertNotNil(subcat.value(forKey: "category"))
        
        dropContainer(container)
    }
  
    // https://github.com/3lvis/Sync/issues/422

    // -----------
    // One to many
    // -----------

    func test422OneToManyOperationOptionsInsert() {
        let container = NSPersistentContainer(modelName: "422OneToMany")
        let initial = Helper.objectsFromJSON("422-one-to-many-insert-option-initial.json") as! [[String: Any]]

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initial, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 1)

        let updated = Helper.objectsFromJSON("422-one-to-many-insert-option-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed: "User", operations: [.insert, .update, .delete, .insertRelationships], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 2)

        let updatedMessage = Helper.fetchEntity("Message", predicate: NSPredicate(format: "id = 101"), inContext: container.viewContext).first
        XCTAssertEqual(updatedMessage?.value(forKey: "text") as? String, "101")

        dropContainer(container)
    }

    func test422OneToManyOperationOptionsUpdateRelationships() {
        let container = NSPersistentContainer(modelName: "422OneToMany")

        let initial = Helper.objectsFromJSON("422-one-to-many-update-option-initial.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initial, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 1)

        let updated = Helper.objectsFromJSON("422-one-to-many-update-option-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed: "User", operations: [.insert, .update, .delete, .updateRelationships], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 1)

        let updatedMessage = Helper.fetchEntity("Message", predicate: NSPredicate(format: "id = 101"), inContext: container.viewContext).first
        XCTAssertEqual(updatedMessage?.value(forKey: "text") as? String, "updated-101")

        dropContainer(container)
    }

    func test422OneToManyOperationOptionsDeleteRelationships() {
        let container = NSPersistentContainer(modelName: "422OneToMany")

        let initial = Helper.objectsFromJSON("422-one-to-many-delete-option-initial.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initial, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 2)

        let updated = Helper.objectsFromJSON("422-one-to-many-delete-option-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed: "User", operations: [.insert, .update, .delete, .deleteRelationships], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 1)

        let updatedMessage = Helper.fetchEntity("Message", predicate: NSPredicate(format: "id = 102"), inContext: container.viewContext).first
        XCTAssertEqual(updatedMessage?.value(forKey: "text") as? String, "102")

        dropContainer(container)
    }

    // -----------
    // Many to many
    // -----------

    func test422ManyToManyOperationOptionsInsert() {
        let container = NSPersistentContainer(modelName: "422ManyToMany")
        let initial = Helper.objectsFromJSON("422-many-to-many-insert-option-initial.json") as! [[String: Any]]

        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initial, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 1)

        let updated = Helper.objectsFromJSON("422-many-to-many-insert-option-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed: "User", operations: [.insert, .update, .delete, .insertRelationships], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 2)

        let updatedMessage = Helper.fetchEntity("Message", predicate: NSPredicate(format: "id = 101"), inContext: container.viewContext).first
        XCTAssertEqual(updatedMessage?.value(forKey: "text") as? String, "101")

        dropContainer(container)
    }

    func test422ManyToManyOperationOptionsUpdateRelationships() {
        let container = NSPersistentContainer(modelName: "422ManyToMany")

        let initial = Helper.objectsFromJSON("422-many-to-many-update-option-initial.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initial, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 1)

        let updated = Helper.objectsFromJSON("422-many-to-many-update-option-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed: "User", operations: [.insert, .update, .delete, .updateRelationships], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 1)

        let updatedMessage = Helper.fetchEntity("Message", predicate: NSPredicate(format: "id = 101"), inContext: container.viewContext).first
        XCTAssertEqual(updatedMessage?.value(forKey: "text") as? String, "updated-101")

        dropContainer(container)
    }

    func test422ManyToManyOperationOptionsDeleteRelationships() {
        let container = NSPersistentContainer(modelName: "422ManyToMany")

        let initial = Helper.objectsFromJSON("422-many-to-many-delete-option-initial.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initial, inEntityNamed: "User", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Message", inContext: container.viewContext), 2)

        let updated = Helper.objectsFromJSON("422-many-to-many-delete-option-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed: "User", operations: [.insert, .update, .delete, .deleteRelationships], completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)
        // count the messages that user 1 has instead of counting all messages
        let userMessageCount = Helper.countForEntity("Message", predicate: NSPredicate(format: "ANY users.id = 1"), inContext: container.viewContext)
        XCTAssertEqual(userMessageCount, 1)

        let updatedMessage = Helper.fetchEntity("Message", predicate: NSPredicate(format: "id = 102"), inContext: container.viewContext).first
        XCTAssertEqual(updatedMessage?.value(forKey: "text") as? String, "102")

        dropContainer(container)
    }

    // https://github.com/3lvis/Sync/issues/476
    func test476() {
        let container = NSPersistentContainer(modelName: "476")

        let data = Helper.objectsFromJSON("476.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(data, inEntityNamed: "FitnessProfile", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("FitnessProfile", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("UserWeight", inContext: container.viewContext), 1)

        dropContainer(container)
    }

    func test480() {
        let container = NSPersistentContainer(modelName: "480")

        let data = Helper.objectsFromJSON("480.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(data, inEntityNamed: "Report", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(Helper.countForEntity("Report", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("HistoryItem", inContext: container.viewContext), 6)

        dropContainer(container)
    }
    
    func test519() {
        
        let container = NSPersistentContainer(modelName: "519")
        
        let data = Helper.objectsFromJSON("519.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(data, inEntityNamed: "Book", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(Helper.countForEntity("Book", inContext: container.viewContext), 2)
        XCTAssertEqual(Helper.countForEntity("Author", inContext: container.viewContext), 3)
        
        dropContainer(container)
    }
    
    // Syncing two sets of objects eg. lists and items individually. Then adding the items to the list in an order, loses the order.
    func testUpdateManytoManyRelationship() {
        let container = NSPersistentContainer(modelName: "ordered-many-to-many-update")
        
        let initialItems = Helper.objectsFromJSON("inital-ordered-many-to-many-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initialItems, inEntityNamed:"Item", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 5)

        let initialList = Helper.objectsFromJSON("ordered-many-to-many-update-inital.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initialList, inEntityNamed:"List", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("List", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 5)
        
        let unpopulatedList = Helper.fetchEntity("List", predicate:nil, inContext: container.viewContext).first
        let unpopulatedListItems = unpopulatedList?.value(forKey:"items") as! NSOrderedSet
        XCTAssertEqual(unpopulatedListItems.count,  0)
        
        let updated = Helper.objectsFromJSON("ordered-many-to-many-update-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed:"List", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("List", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 5)
        
        let list = Helper.fetchEntity("List", predicate:nil, inContext: container.viewContext).first
        let items = list?.value(forKey:"items") as! NSOrderedSet
        XCTAssertEqual(items.count,  5)
        
        // 1,3,2,5,4
        XCTAssertEqual((items.firstObject as! NSManagedObject).value(forKey:"id") as? Int16, 1)
        XCTAssertEqual((items.object(at: 1) as! NSManagedObject).value(forKey:"id") as? Int16, 3)
        XCTAssertEqual((items.object(at: 2) as! NSManagedObject).value(forKey:"id") as? Int16, 2)
        XCTAssertEqual((items.object(at: 3) as! NSManagedObject).value(forKey:"id") as? Int16, 5)
        XCTAssertEqual((items.lastObject as! NSManagedObject).value(forKey:"id") as? Int16, 4)
        
        dropContainer(container)
    }
    
    func testAddingAndReorderingManyToManyRelationshipByObjects() {
        let container = NSPersistentContainer(modelName: "ordered-many-to-many-update")
        
        let initialItems = Helper.objectsFromJSON("453-to-many-ordered-relationship-objects-initial.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initialItems, inEntityNamed:"List", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("List", inContext: container.viewContext), 1)
        
        // 1, 2, 3
        var list = Helper.fetchEntity("List", predicate:nil, inContext: container.viewContext).first
        var items = list?.value(forKey:"items") as! NSOrderedSet
        XCTAssertEqual((items.firstObject as! NSManagedObject).value(forKey:"id") as? Int16, 1)
        XCTAssertEqual((items.object(at: 1) as! NSManagedObject).value(forKey:"id") as? Int16, 2)
        XCTAssertEqual((items.lastObject as! NSManagedObject).value(forKey:"id") as? Int16, 3)
        
        let updated = Helper.objectsFromJSON("453-to-many-ordered-relationship-objects-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed:"List", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("List", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 4)
        
        // 3, 4, 5, 2
        list = Helper.fetchEntity("List", predicate:nil, inContext: container.viewContext).first
        items = list?.value(forKey:"items") as! NSOrderedSet
        XCTAssertEqual((items.firstObject as! NSManagedObject).value(forKey:"id") as? Int16, 3)
        XCTAssertEqual((items.object(at: 1) as! NSManagedObject).value(forKey:"id") as? Int16, 4)
        XCTAssertEqual((items.object(at: 2) as! NSManagedObject).value(forKey:"id") as? Int16, 5)
        XCTAssertEqual((items.lastObject as! NSManagedObject).value(forKey:"id") as? Int16, 2)
        
        dropContainer(container)
    }
    
    func testAddingAndReorderingManyToManyRelationshipByIds() {
        let container = NSPersistentContainer(modelName: "ordered-many-to-many-update")
        
        let initialItems = Helper.objectsFromJSON("453-to-many-ordered-relationship-objects-initial.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(initialItems, inEntityNamed:"List", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 3)
        XCTAssertEqual(Helper.countForEntity("List", inContext: container.viewContext), 1)
        
        // 1, 2, 3
        var list = Helper.fetchEntity("List", predicate:nil, inContext: container.viewContext).first
        var items = list?.value(forKey:"items") as! NSOrderedSet
        XCTAssertEqual((items.firstObject as! NSManagedObject).value(forKey:"id") as? Int16, 1)
        XCTAssertEqual((items.object(at: 1) as! NSManagedObject).value(forKey:"id") as? Int16, 2)
        XCTAssertEqual((items.lastObject as! NSManagedObject).value(forKey:"id") as? Int16, 3)

        // Add the future 2 items 4, 5 since we're sycing by ids.
        let additionalItems = Helper.objectsFromJSON("453-to-many-ordered-relationship-item-insert.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(additionalItems, inEntityNamed:"Item", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 5)
        
        let updated = Helper.objectsFromJSON("453-to-many-ordered-relationship-ids-update.json") as! [[String: Any]]
        syncExpectation = expectation(description: "Sync Expectation")
        container.sync(updated, inEntityNamed:"List", completion: syncCompletion)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(Helper.countForEntity("List", inContext: container.viewContext), 1)
        XCTAssertEqual(Helper.countForEntity("Item", inContext: container.viewContext), 5)
        
        // 3, 4, 5, 2
        list = Helper.fetchEntity("List", predicate:nil, inContext: container.viewContext).first
        items = list?.value(forKey:"items") as! NSOrderedSet
        XCTAssertEqual((items.firstObject as! NSManagedObject).value(forKey:"id") as? Int16, 3)
        XCTAssertEqual((items.object(at: 1) as! NSManagedObject).value(forKey:"id") as? Int16, 4)
        XCTAssertEqual((items.object(at: 2) as! NSManagedObject).value(forKey:"id") as? Int16, 5)
        XCTAssertEqual((items.lastObject as! NSManagedObject).value(forKey:"id") as? Int16, 2)
        
        dropContainer(container)
    }
}

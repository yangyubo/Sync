import XCTest

import CoreData
import Sync

class UpdateTests: XCTestCase {
    func testUpdateWithObjectNotFound() {
        let container = NSPersistentContainer(modelName: "id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: container.viewContext)
        user.setValue("id", forKey: "id")
        try! container.viewContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))
        let id = try! Sync.update("someotherid", with: [String: Any](), inEntityNamed: "User", using: container.viewContext)
        XCTAssertNil(id)
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))

        dropContainer(container)
    }

    func testUpdateWhileMaintainingTheSameID() {
        let container = NSPersistentContainer(modelName: "id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: container.viewContext)
        user.setValue("id", forKey: "id")
        try! container.viewContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))
        let updatedObject = try! Sync.update("id", with: ["name": "bossy"], inEntityNamed: "User", using: container.viewContext)
        XCTAssertEqual(updatedObject?.value(forKey: "id") as? String, "id")
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))

        container.viewContext.refresh(user, mergeChanges: false)

        XCTAssertEqual(user.value(forKey: "name") as? String, "bossy")

        dropContainer(container)
    }

    func testUpdateWithJSONThatHasNewID() {
        let container = NSPersistentContainer(modelName: "id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: container.viewContext)
        user.setValue("id", forKey: "id")
        try! container.viewContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))
        let updatedObject = try! Sync.update("id", with: ["id": "someid"], inEntityNamed: "User", using: container.viewContext)
        XCTAssertEqual(updatedObject?.value(forKey: "id") as? String, "someid")
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))

        dropContainer(container)
    }
}

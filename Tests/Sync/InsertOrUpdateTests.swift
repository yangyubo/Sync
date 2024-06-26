import XCTest

import CoreData
import Sync

class InsertOrUpdateTests: XCTestCase {
    func testInsertOrUpdateWithStringID() {
        let container = NSPersistentContainer(modelName: "id")
        let json = ["id": "id", "name": "name"]
        let insertedObject = try! container.insertOrUpdate(json, inEntityNamed: "User")
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))

        XCTAssertEqual(insertedObject.value(forKey: "id") as? String, "id")
        XCTAssertEqual(insertedObject.value(forKey: "name") as? String, "name")

        if let object = Helper.fetchEntity("User", inContext: container.viewContext).first {
            XCTAssertEqual(object.value(forKey: "id") as? String, "id")
            XCTAssertEqual(object.value(forKey: "name") as? String, "name")
        } else {
            XCTFail()
        }
        dropContainer(container)
    }

    func testInsertOrUpdateWithNumberID() {
        let container = NSPersistentContainer(modelName: "Tests")
        let json = ["id": 1]
        try! container.insertOrUpdate(json, inEntityNamed: "User")
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))
        dropContainer(container)
    }

    func testInsertOrUpdateUpdate() {
        let container = NSPersistentContainer(modelName: "id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: container.viewContext)
        user.setValue("id", forKey: "id")
        user.setValue("old", forKey: "name")
        try! container.viewContext.save()

        let json = ["id": "id", "name": "new"]
        let updatedObject = try! container.insertOrUpdate(json, inEntityNamed: "User")
        XCTAssertEqual(updatedObject.value(forKey: "id") as? String, "id")
        XCTAssertEqual(updatedObject.value(forKey: "name") as? String, "new")

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))
        if let object = Helper.fetchEntity("User", inContext: container.viewContext).first {
            XCTAssertEqual(object.value(forKey: "id") as? String, "id")
            XCTAssertEqual(object.value(forKey: "name") as? String, "new")
        } else {
            XCTFail()
        }
        dropContainer(container)
    }
}

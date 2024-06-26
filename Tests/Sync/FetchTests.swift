import XCTest

import CoreData
import Sync

class FetchTests: XCTestCase {
    func testFetch() {
        let container = NSPersistentContainer(modelName: "id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: container.viewContext)
        user.setValue("id", forKey: "id")
        user.setValue("dada", forKey: "name")
        try! container.viewContext.save()
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))

        let fetched = try! container.fetch("id", inEntityNamed: "User")
        XCTAssertEqual(fetched?.value(forKey: "id") as? String, "id")
        XCTAssertEqual(fetched?.value(forKey: "name") as? String, "dada")

        try! Sync.delete("id", inEntityNamed: "User", using: container.viewContext)
        XCTAssertEqual(0, Helper.countForEntity("User", inContext: container.viewContext))

        let newFetched = try! container.fetch("id", inEntityNamed: "User")
        XCTAssertNil(newFetched)

        dropContainer(container)
    }
}

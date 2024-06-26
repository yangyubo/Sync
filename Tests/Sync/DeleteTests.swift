import XCTest

import CoreData
import Sync

class DeleteTests: XCTestCase {
    func testDeleteWithStringID() {
        let container = NSPersistentContainer(modelName: "id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: container.viewContext)
        user.setValue("id", forKey: "id")
        try! container.viewContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))
        
        let expectation = expectation(description: "\(#function)")
        try! container.delete("id", inEntityNamed: "User") {_ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        
        XCTAssertEqual(0, Helper.countForEntity("User", inContext: container.viewContext))

        dropContainer(container)
    }

    func testDeleteWithNumberID() {
        let container = NSPersistentContainer(modelName: "Tests")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: container.viewContext)
        user.setValue(1, forKey: "remoteID")
        try! container.viewContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: container.viewContext))
        
        let expectation = expectation(description: "\(#function)")
        try! container.delete(1, inEntityNamed: "User") { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        
        XCTAssertEqual(0, Helper.countForEntity("User", inContext: container.viewContext))

        dropContainer(container)
    }
}

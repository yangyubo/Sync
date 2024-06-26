import XCTest

import CoreData
import Sync

class SyncDelegateTests: XCTestCase {
    
    func testWillInsertJSON() {
        let container = NSPersistentContainer(modelName: "Tests")

        let json = [["id": 9, "completed": false]]
        let syncOperation = Sync(changes: json, inEntityNamed: "User", persistentContainer: container)
        syncOperation.delegate = self
        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 0)
        
        let expectation = expectation(description: "Sync Expectation")
        syncOperation.start {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(Helper.countForEntity("User", inContext: container.viewContext), 1)

        if let task = Helper.fetchEntity("User", inContext: container.viewContext).first {
            XCTAssertEqual(task.value(forKey: "remoteID") as? Int, 9)
            XCTAssertEqual(task.value(forKey: "localID") as? String, "local")
        } else {
            XCTFail()
        }
        dropContainer(container)
    }
}

extension SyncDelegateTests: SyncDelegate {
    func sync(_ sync: Sync, willInsert json: [String: Any], in entityNamed: String, parent: NSManagedObject?) -> [String: Any] {
        var newJSON = json
        newJSON["localID"] = "local"

        return newJSON
    }
}

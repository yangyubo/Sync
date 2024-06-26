import XCTest
import CoreData
@testable import Sync

class NSPropertyDescription_SyncTests: XCTestCase {
    func testOldCustomKey() {
        let container = NSPersistentContainer(modelName: "RemoteKey")

        if let entity = NSEntityDescription.entity(forEntityName: "Entity", in: container.viewContext) {
            let dayAttribute = entity.sync_attributes().filter { $0.name == "old" }.first
            if let dayAttribute = dayAttribute {
                XCTAssertEqual(dayAttribute.customKey(), "custom_old")
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }

        dropContainer(container)
    }

    func testCurrentCustomKey() {
        let container = NSPersistentContainer(modelName: "RemoteKey")

        if let entity = NSEntityDescription.entity(forEntityName: "Entity", in: container.viewContext) {
            let dayAttribute = entity.sync_attributes().filter { $0.name == "current" }.first
            if let dayAttribute = dayAttribute {
                XCTAssertEqual(dayAttribute.customKey(), "custom_current")
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }

        dropContainer(container)
    }

    func testIsCustomPrimaryKey() {
        // TODO
    }

    func testShouldExportAttribute() {
        // TODO
    }

    func testCustomTransformerName() {
        // TODO
    }
}

import CoreData
import XCTest


class FillWithDictionaryTests: XCTestCase {

    func testBug112() {
        let container = NSPersistentContainer(modelName: "112")

        let owner = Helper.insertEntity("Owner", container: container)
        owner.setValue(1, forKey: "id")

        let taskList = Helper.insertEntity("TaskList", container: container)
        taskList.setValue(1, forKey: "id")
        taskList.setValue(owner, forKey: "owner")

        let task = Helper.insertEntity("Task", container: container)
        task.setValue(1, forKey: "id")
        task.setValue(taskList, forKey: "taskList")
        task.setValue(owner, forKey: "owner")

        try! container.viewContext.save()

        let ownerBody = [
            "id": 1,
            ] as [String: Any]
        let taskBoby = [
            "id": 1,
            "owner": ownerBody,
            ] as [String: Any]
        let expected = [
            "id": 1,
            "owner": ownerBody,
            "tasks": [taskBoby],
            ] as [String: Any]

        XCTAssertEqual(expected as NSDictionary, taskList.hyp_dictionary(.array) as NSDictionary)

        dropContainer(container)
    }

    func testBug121() {
        let container = NSPersistentContainer(modelName: "121")

        let album = Helper.insertEntity("Album", container: container)
        let json = [
            "id": "a",
            "coverPhoto": ["id": "b"],
            ] as [String: Any]
        album.hyp_fill(with: json)

        XCTAssertNotNil(album.value(forKey: "coverPhoto"))

        dropContainer(container)
    }

    func testBug123() {
        let container = NSPersistentContainer(modelName: "123")
        let user = Helper.insertEntity("User", container: container)
        user.setValue(1, forKey: "id")
        user.setValue("Ignore me", forKey: "name")

        try! container.viewContext.save()
        let expected = [
            "id": 1,
            ] as [String: Any]

        XCTAssertEqual(expected as NSDictionary, user.hyp_dictionary(.none) as NSDictionary)

        dropContainer(container)
    }

    func testBug129() {
        ValueTransformer.setValueTransformer(BadAPIValueTransformer(), forName: NSValueTransformerName(rawValue: "BadAPIValueTransformer"))

        let container = NSPersistentContainer(modelName: "129")

        let user = Helper.insertEntity("User", container: container)
        let json = [
            "name": ["bad-backend-dev"],
            ] as [String: Any]
        user.hyp_fill(with: json)
        
        XCTAssertEqual(user.value(forKey: "name") as? String, "bad-backend-dev")
        
        dropContainer(container)
    }
}

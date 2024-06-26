//
//  File.swift
//  
//
//  Created by Lee Avery on 19/01/2022.
//

import Foundation
import Sync
import XCTest
import CoreData

class SyncDictionaryTests : XCTestCase {
    
    let testDate: Date = Date()
    
    
    // MARK: Set up
    
    let container = NSPersistentContainer(modelName: "Model")
    
    func entityNamed(_ entityName: String, inContext context: NSManagedObjectContext) -> Any? {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
    }
    
    func userUsingContainer(_ container: NSPersistentContainer) -> NSManagedObject {
        let user: NSManagedObject = self.entityNamed("User", inContext: container.viewContext) as! NSManagedObject
        user.setValue(25, forKey: "age")
        user.setValue(self.testDate, forKey: "birthDate")
        user.setValue(235, forKey:"contractID")
        user.setValue("ABC8283", forKey:"driverIdentifier")
        user.setValue("John", forKey:"firstName")
        user.setValue("Sid", forKey:"lastName")
        user.setValue("John Description", forKey:"userDescription")
        user.setValue(111, forKey:"remoteID")
        user.setValue("Manager", forKey:"userType")
        user.setValue(self.testDate, forKey:"createdAt")
        user.setValue(self.testDate, forKey:"updatedAt")
        user.setValue(30, forKey:"numberOfAttendes")
        user.setValue("raw", forKey:"rawSigned")
        
        var hobbies: Data? = nil
        do {
            hobbies = try NSKeyedArchiver.archivedData(withRootObject: ["Football", "Soccer", "Code", "More Code"], requiringSecureCoding: true)
            user.setValue(hobbies, forKey: "hobbies")
        } catch {
            assertionFailure("NSkeyedArchiver hobbies failed" , file: "SyncDictionaryTests", line: 49)
        }
        
        
        var expenses: Data? = nil
        do {
            expenses = try NSKeyedArchiver.archivedData(
                withRootObject: [
                    "cake": 12.50,
                    "juice": 0.50
                ],
                requiringSecureCoding: true)
            user.setValue(expenses, forKey: "expenses")
        } catch {
            assertionFailure("NSKeyedArchiver expenses failed", file: "SyncDictionaryTests", line: 57)
        }
        
        var note  = self.noteWithID(1, inContext: self.container.viewContext)
        note.setValue(user, forKey: "user")
        
        note = self.noteWithID(14, inContext: self.container.viewContext)
        note.setValue(user, forKey: "user")
        note.setValue(true, forKey: "destroy")
        
        note = self.noteWithID(7, inContext: self.container.viewContext)
        note.setValue(user, forKey: "user")
        
        let company: NSManagedObject = self.companyWithID(1, andName: "Facebook", inContext: self.container.viewContext)
        company.setValue(user, forKey: "user")
        return user
        
    }
    
    func noteWithID(_ remoteID: Int, inContext context: NSManagedObjectContext) -> NSManagedObject{
        let note: NSManagedObject = self.entityNamed("Note", inContext: context) as! NSManagedObject
        note.setValue(remoteID, forKey: "remoteID")
        note.setValue("This is the text for the note \(remoteID)", forKey: "text")
        
        return note
    }
    
    func orderedNoteWithID(_ remoteID: Int, inContext context: NSManagedObjectContext) -> NSManagedObject {
        let note: NSManagedObject = self.entityNamed("OrderedNote", inContext: context) as! NSManagedObject
        note.setValue(remoteID, forKey: "remoteID")
        note.setValue("This is the text for note \(remoteID)", forKey: "text")
        
        return note
    }
    
    func companyWithID(_ remoteID: Int, andName name: String, inContext context: NSManagedObjectContext) -> NSManagedObject {
        let company: NSManagedObject = self.entityNamed("Company", inContext: context) as! NSManagedObject
        company.setValue(remoteID, forKey: "remoteID")
        company.setValue(name, forKey: "name")
        
        return company
    }
    
    
    // MARK: hyp_dictionary
    
    func userDictionaryWithNoRelationships() -> [String: Any?] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        // formatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        let resultDateString = formatter.string(from: self.testDate)
        
        var comparedDictionary: [String: Any] = Dictionary()
        comparedDictionary["age_of_person"] = 25
        comparedDictionary["birth_date"] = resultDateString
        comparedDictionary["contract_id"] = 235
        comparedDictionary["created_at"] = resultDateString
        comparedDictionary["description"] = "John Description"
        comparedDictionary["driver_identifier_str"] = "ABC8283"
        
        var expenses: Data?
        do {
            expenses = try NSKeyedArchiver.archivedData(withRootObject: ["cake" : 12.50,
                                                                         "juice" : 0.50],
                                                        requiringSecureCoding: true)
            comparedDictionary["expenses"] = expenses
        } catch {
            assertionFailure("NSKeyedArchiver expenses failed", file: "SyncDictionaryTests", line: 131)
        }
        
        comparedDictionary["first_name"] = "John"
        
        var hobbies: Data?
        do {
            hobbies = try NSKeyedArchiver.archivedData(withRootObject: ["Football", "Soccer", "Code", "More Code"],
                                                       requiringSecureCoding: true)
            comparedDictionary["hobbies"] = hobbies
        } catch {
            assertionFailure("NSKeyedArchiver hobbies failed", file: "SyncDictionaryTests", line: 143)
        }
        
        comparedDictionary["id"] = 111
        comparedDictionary["ignored_parameter"] = NSNull()
        comparedDictionary["last_name"] = "Sid"
        comparedDictionary["number_of_attendes"] = 30
        comparedDictionary["type"] = "Manager"
        comparedDictionary["updated_at"] = resultDateString
        comparedDictionary["signed"] = "raw"

        return comparedDictionary
    }
    
    func testDictionaryWithNoRelationships() {
        let user: NSManagedObject = self.userUsingContainer(container)
        let dictionary = user.hyp_dictionary(.none)
        let compareDictionary = self.userDictionaryWithNoRelationships()
        for (key, value) in compareDictionary {
            if let comparedValue = dictionary[key] {
                XCTAssertEqual(value as? NSObject, comparedValue as? NSObject)
            }
        }
        XCTAssertEqual(dictionary as NSDictionary, compareDictionary as NSDictionary)
    }
    
    func testDictionaryArrayRelationships() {
        let user: NSManagedObject = self.userUsingContainer(container)
        var dictionary = user.hyp_dictionary(.array)
        var comparedDictionary = userDictionaryWithNoRelationships()
        comparedDictionary["company"] = ["id" : 1,
                                        "name" : "Facebook"]
        

        let notes : Array<[String: Any]> = dictionary["notes"] as! Array<[String: Any]>
        let nameDescriptor = NSSortDescriptor(key: "id", ascending: true)
        let sortedNotes = (notes as NSArray).sortedArray(using: [nameDescriptor])

        dictionary["notes"] = sortedNotes
        
        let note1 = ["destroy" : nil,
                     "id" : 1,
                     "text" : "This is the text for the note 1"] as [String : Any?]
        let note2 = ["destroy" : nil,
                     "id" : 7,
                     "text" : "This is the text for the note 7"] as [String : Any?]
        let note3 = ["destroy" : 1,
                     "id" : 14,
                     "text" : "This is the text for the note 14"] as [String : Any?]
        comparedDictionary["notes"] = [note1, note2, note3]
        
        for (key, value) in comparedDictionary {
            if let comparedValue = dictionary[key] {
                XCTAssertEqual(value as? NSObject, comparedValue as? NSObject)
            }
        }
        XCTAssertEqual(dictionary as NSDictionary, comparedDictionary as NSDictionary)
    }
    
    
    func testDictionaryArrayRelationshipsOrdered() {
        let container = NSPersistentContainer(modelName: "Ordered")
        
        let user: NSManagedObject = entityNamed("OrderedUser", inContext: container.viewContext) as! NSManagedObject
        
        user.setValue("raw", forKey:"rawSigned")

        user.setValue("raw", forKey:"rawSigned")
        user.setValue(25, forKey:"age")
        user.setValue(self.testDate, forKey:"birthDate")
        user.setValue(235, forKey:"contractID")
        user.setValue("ABC8283", forKey:"driverIdentifier")
        user.setValue("John", forKey:"firstName")
        user.setValue("Sid", forKey:"lastName")
        user.setValue("John Description", forKey:"orderedUserDescription")
        user.setValue(111, forKey:"remoteID")
        user.setValue("Manager", forKey:"orderedUserType")
        user.setValue(self.testDate, forKey:"createdAt")
        user.setValue(self.testDate, forKey:"updatedAt")
        user.setValue(30, forKey:"numberOfAttendes")
        
        var hobbies: Data?
        do {
            hobbies = try NSKeyedArchiver.archivedData(withRootObject: ["Football", "Soccer", "Code", "More Code"],
                                                       requiringSecureCoding: true)
            user.setValue(hobbies, forKey: "hobbies")
        } catch {
            assertionFailure("NSKeyedArchiver hobbies failed", file: "SyncDictionaryTests", line: 222)
        }
        
        var expenses: Data? = nil
        do {
            expenses = try NSKeyedArchiver.archivedData(withRootObject: ["cake" : 12.50,
                                                                         "juice" : 0.50],
                                                        requiringSecureCoding: true)
            user.setValue(expenses, forKey: "expenses")
        } catch {
            assertionFailure("NSKeyedArchiver expenses failed", file: "SyncDictionaryTests", line: 57)
        }
        
        var note = orderedNoteWithID(1, inContext: container.viewContext)
        note.setValue(user, forKey: "user")
        
        note = orderedNoteWithID(14, inContext: container.viewContext)
        note.setValue(user, forKey: "user")
        note.setValue(true, forKey: "destroy")
        
        note = orderedNoteWithID(7, inContext: container.viewContext)
        note.setValue(user, forKey: "user")
        
        var dictionary = user.hyp_dictionary(.array)
        var comparedDictionary = userDictionaryWithNoRelationships()
        
        
        let notes : Array<[String: Any]> = dictionary["notes"] as! Array<[String: Any]>
        let nameDescriptor = NSSortDescriptor(key: "id", ascending: true)
        let sortedNotes = (notes as NSArray).sortedArray(using: [nameDescriptor])
        
        dictionary["notes"] = sortedNotes
        
        let note1 = ["destroy" : nil,
                     "id" : 1,
                     "text" : "This is the text for note 1"] as [String : Any?]
        let note2 = ["destroy" : nil,
                     "id" : 7,
                     "text" : "This is the text for note 7"] as [String : Any?]
        let note3 = ["destroy" : 1,
                     "id" : 14,
                     "text" : "This is the text for note 14"] as [String : Any]
        comparedDictionary["notes"] = [note1, note2, note3]
        
        for (key, value) in comparedDictionary {
            XCTAssertEqual(value as? NSObject, dictionary[key] as? NSObject)
        }
        
        
        XCTAssertEqual(dictionary as NSDictionary, comparedDictionary as NSDictionary)
        
        let description = dictionary["description"] as! String
        XCTAssertEqual(description, "John Description")
        
        let type = (dictionary["type"] as! String)
        XCTAssertEqual(type, "Manager")
    }
    
    
    func testDictionaryDeepRelationships() {
        let building = entityNamed("Building", inContext: container.viewContext) as! NSManagedObject
        building.setValue(1, forKey: "remoteID")

        let park = entityNamed("Park", inContext: container.viewContext) as! NSManagedObject
        park.setValue(1, forKey: "remoteID")

        var parks: Set<AnyHashable> = (building.value(forKey: "parks") as! Set<AnyHashable>)
        let _ = parks.insert(park)
        building.setValue(parks, forKey:"parks")

        let apartment: NSManagedObject = entityNamed("Apartment", inContext: container.viewContext) as! NSManagedObject
        apartment.setValue(1, forKey: "remoteID")

        let room: NSManagedObject = entityNamed("Room", inContext: container.viewContext) as! NSManagedObject
        room.setValue(1, forKey:"remoteID")

        var rooms: Set<AnyHashable> = (apartment.value(forKey: "rooms") as! Set<AnyHashable>)
        let _ = rooms.insert(room)
        apartment.setValue(rooms, forKey: "rooms")
    
        var apartments = building.value(forKey: "apartments") as! Set<AnyHashable>
        let _ = apartments.insert(apartment)
        building.setValue(apartments, forKey: "apartments")
        
        let buildingDictionary = building.hyp_dictionary(.array)
        var compared: [String: Any] = Dictionary()
        let roomsArray: Array<[String: Any?]> = [["id" : 1]]
        let apartmentsArray: Array<[String: Any?]> = [["id" : 1, "rooms" : roomsArray]]
        let parksArray: Array<[String: Any?]> = [["id" : 1]]
        compared["id"] = 1;
        compared["apartments"] = apartmentsArray;
        compared["parks"] = parksArray;

        XCTAssertEqual(buildingDictionary as NSDictionary, compared as NSDictionary);
    }
    
    func testDictionaryValuesKindOfClass() {
        let user = userUsingContainer(container)
        let dictionary = user.hyp_dictionary()
        
        XCTAssertTrue(dictionary["age_of_person"] is NSNumber)

        XCTAssertTrue(dictionary["birth_date"] is NSString)

        XCTAssertTrue(dictionary["contract_id"] is NSNumber)

        XCTAssertTrue(dictionary["created_at"] is NSString)

        XCTAssertTrue(dictionary["description"] is NSString)

        XCTAssertTrue(dictionary["driver_identifier_str"] is NSString)

        XCTAssertTrue(dictionary["expenses"] is NSData)

        XCTAssertTrue(dictionary["first_name"] is NSString)

        XCTAssertTrue(dictionary["hobbies"] is NSData)

        XCTAssertTrue(dictionary["id"] is NSNumber)

        XCTAssertNil(dictionary["ignore_transformable"] as Any?);

        XCTAssertTrue(dictionary["ignored_parameter"] is NSNull)

        XCTAssertTrue(dictionary["last_name"] is NSString)

        XCTAssertTrue(dictionary["notes_attributes"] is NSDictionary)

        XCTAssertTrue(dictionary["number_of_attendes"] is NSNumber)

        XCTAssertTrue(dictionary["type"] is NSString)

        XCTAssertTrue(dictionary["updated_at"] is NSString)
    }
    
    
    func testRecursive() {
        let megachild: NSManagedObject = entityNamed("Recursive", inContext: container.viewContext) as! NSManagedObject
        megachild.setValue("megachild", forKey: "remoteID")
        
        let grandchild: NSManagedObject = entityNamed("Recursive", inContext: container.viewContext) as! NSManagedObject
        grandchild.setValue("grandchild", forKey: "remoteID")
        
        var recursives: Set<AnyHashable> = (grandchild.value(forKey: "recursives") as? Set<AnyHashable>)!
        let _ = recursives.insert(megachild)
        grandchild.setValue(recursives, forKey: "recursives")
        megachild.setValue(grandchild, forKey: "recursive")
        
        let child: NSManagedObject = entityNamed("Recursive", inContext: container.viewContext) as! NSManagedObject
        child.setValue("child", forKey: "remoteID")
        
        recursives = (child.value(forKey: "recursives") as? Set<AnyHashable>)!
        let _ = recursives.insert(grandchild)
//        child.setValue(recursives, forKey: "recursive")
        grandchild.setValue(child, forKey: "recursive")
        
        let parent: NSManagedObject = entityNamed("Recursive", inContext: container.viewContext) as! NSManagedObject
        parent.setValue("Parent", forKey: "remoteID")
        
        recursives = parent.value(forKey: "recursives") as! Set<AnyHashable>
        let _ = recursives.insert(child)
        parent.setValue(recursives, forKey: "recursives")
        child.setValue(parent, forKey: "recursive")
        
        let dictionary: [String: Any?] = parent.hyp_dictionary(.array)
        let megachildArray = [["id" : "megachild", "recursives" : []]]
        let grandchildArray = [["id" : "grandchild", "recursives" : megachildArray]]
        let childArray = [["id" : "child", "recursives" : grandchildArray]]
        
        let parentDictionary = ["id" : "Parent", "recursives" : childArray] as [String : Any]
        
        XCTAssertEqual(dictionary as NSDictionary, parentDictionary as NSDictionary)
        
    }
    
}


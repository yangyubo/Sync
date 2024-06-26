//
//  File.swift
//  
//
//  Created by Lee Avery on 20/01/2022.
//

import Foundation
import Sync
import XCTest
import CoreData


class SyncFillWithDictionaryTests : XCTestCase {
    
    let testDate = Date()
    
    let container = NSPersistentContainer(modelName: "Model")
    
    
    func entityNamed(_ entityName: String, inContext context: NSManagedObjectContext) -> Any? {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
    }
    
    func userUsingContainer(_ container: NSPersistentContainer) -> NSManagedObject {
        let user = entityNamed("User", inContext: container.viewContext) as! NSManagedObject
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
            hobbies = try NSKeyedArchiver.archivedData(withRootObject: ["Football", "Soccer", "Code", "More code"], requiringSecureCoding: true)
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
    
    
    func companyWithID(_ remoteID: Int, andName name: String, inContext context: NSManagedObjectContext) -> NSManagedObject {
        let company: NSManagedObject = self.entityNamed("Company", inContext: context) as! NSManagedObject
        company.setValue(remoteID, forKey: "remoteID")
        company.setValue(name, forKey: "name")
        
        return company
    }
    
    
    // MARK: hyp_fillWithDictionary
    
    func testAllAttributes() {
        let values : [String: Any] = ["integer_string" : "16",
                                 "integer16" : 16,
                                 "integer32" : 32,
                                 "integer64" : 64,
                                 "decimal_string" : "12.2",
                                 "decimal" : 12.2,
                                 "double_value_string": "12.2",
                                 "double_value": 12.2,
                                 "float_value_string" : "12.2",
                                 "float_value" : 12.2,
                                 "string" : "string",
                                 "boolean" : true,
                                 "binary_data" : "Data",
                                 "transformable" : "Ignore me, too",
                                 "custom_transformer_string" : "Foo &amp; bar",
                                 "uuid": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
                                 "uri": "https://www.apple.com/"
                                 ]
        
        
        ValueTransformer.setValueTransformer(SyncTestValueTransformer(), forName: NSValueTransformerName("SyncTestValueTransformer"))
        
        let attributes = entityNamed("Attribute", inContext: container.viewContext) as! NSManagedObject
        attributes.hyp_fill(with: values)
        
        
        XCTAssertEqual(attributes.value(forKey: "integerString") as! Int, 16)
        XCTAssertEqual(attributes.value(forKey: "integer16") as! Int, 16)
        XCTAssertEqual(attributes.value(forKey: "integer32") as! Int, 32)
        XCTAssertEqual(attributes.value(forKey: "integer64") as! Int, 64)
        
        XCTAssertEqual(attributes.value(forKey: "decimalString") as? Decimal, Decimal(string: "12.2"))
        
        XCTAssertTrue(attributes.value(forKey: "decimalString") is Decimal)
        XCTAssertNotEqual(String(describing: type(of: attributes.value(forKey: "decimalString"))), String(describing: type(of: NSNumber.self)))
        
        XCTAssertEqual(attributes.value(forKey: "decimal") as? Decimal, Decimal(string: "12.2"))
        
        XCTAssertTrue(attributes.value(forKey: "decimal") is Decimal)
        XCTAssertNotEqual(String(describing: type(of: attributes.value(forKey: "decimal"))), String(describing: type(of: NSNumber.self)))

        XCTAssertEqual(attributes.value(forKey: "doubleValueString") as! Double, 12.2)
        XCTAssertEqual(attributes.value(forKey: "doubleValue") as! Double, 12.2)
        XCTAssertEqual((attributes.value(forKey: "floatValueString") as! Double), (12 as Double), accuracy: 1.0)
        XCTAssertEqual((attributes.value(forKey: "floatValue") as! Double), (12 as Double), accuracy: 1.0)
        XCTAssertEqual(attributes.value(forKey: "string") as! String, "string")
        XCTAssertEqual(attributes.value(forKey: "boolean") as! Bool, true)
                        
        var testData: Data? = nil
        do {
            testData = try NSKeyedArchiver.archivedData(
                withRootObject: "Data",
                requiringSecureCoding: true)
        } catch {
            assertionFailure("NSKeyedArchiver expenses failed", file: "SyncDictionaryTests", line: 57)
        }
                        
        print(attributes)
        XCTAssertEqual(attributes.value(forKey: "binaryData") as? Data, testData)
        XCTAssertEqual(attributes.value(forKey: "transformable") as? String, nil)
        XCTAssertEqual(attributes.value(forKey: "customTransformerString") as! String, "Foo & bar")
        XCTAssertEqual(attributes.value(forKey: "uuid") as? UUID, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"))
        XCTAssertEqual(attributes.value(forKey: "uri") as? URL, URL(string: "https://www.apple.com/"))
        
    }
    
    
    func testAllAttributesInCamelcase() {
        let values : [String: Any] = ["integerString" : "16",
                                 "integer16" : 16,
                                 "integer32" : 32,
                                 "integer64" : 64,
                                 "decimalString" : "12.2",
                                 "decimal" : 12.2,
                                 "doubleValueString": "12.2",
                                 "doubleValue": 12.2,
                                 "floatValueString" : "12.2",
                                 "floatValue" : 12.2,
                                 "string" : "string",
                                 "boolean" : true,
                                 "binaryData" : "Data",
                                 "transformable" : "Ignore me, too",
                                 "customTransformerString" : "Foo &amp; bar",
                                 "uuid": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
                                 "uri": "https://www.apple.com/"
                                 ]
        
        ValueTransformer.setValueTransformer(SyncTestValueTransformer(), forName: NSValueTransformerName("SyncTestValueTransformer"))

        
        let attributes = entityNamed("Attribute", inContext: container.viewContext) as! NSManagedObject
        attributes.hyp_fill(with: values)
        
        XCTAssertEqual(attributes.value(forKey: "integerString") as? Int, 16)
        XCTAssertEqual(attributes.value(forKey: "integer16") as? Int, 16)
        XCTAssertEqual(attributes.value(forKey: "integer32") as? Int, 32)
        XCTAssertEqual(attributes.value(forKey: "integer64") as? Int, 64)
        
        XCTAssertEqual(attributes.value(forKey: "decimalString") as? Decimal, Decimal(string: "12.2"))
        
        XCTAssertTrue(attributes.value(forKey: "decimalString") is Decimal)
        XCTAssertNotEqual(String(describing: type(of: attributes.value(forKey: "decimalString"))), String(describing: type(of: NSNumber.self)))
        
        XCTAssertEqual(attributes.value(forKey: "decimal") as? Decimal, Decimal(string: "12.2"))
        
        XCTAssertTrue(attributes.value(forKey: "decimal") is Decimal)
        XCTAssertNotEqual(String(describing: type(of: attributes.value(forKey: "decimal"))), String(describing: type(of: NSNumber.self)))

        XCTAssertEqual(attributes.value(forKey: "doubleValueString") as? Double, 12.2)
        XCTAssertEqual(attributes.value(forKey: "doubleValue") as? Double, 12.2)
        XCTAssertEqual((attributes.value(forKey: "floatValueString") as! Double), (12 as Double), accuracy: 1.0)
        XCTAssertEqual((attributes.value(forKey: "floatValue") as! Double), (12 as Double), accuracy:1.0)
        XCTAssertEqual(attributes.value(forKey: "string") as? String, "string")
        XCTAssertEqual(attributes.value(forKey: "boolean") as? Bool, true)
                        
        var testData: Data? = nil
        do {
            testData = try NSKeyedArchiver.archivedData(
                withRootObject: "Data",
                requiringSecureCoding: true)
        } catch {
            assertionFailure("NSKeyedArchiver expenses failed", file: "SyncDictionaryTests", line: 57)
        }
                        
        XCTAssertEqual(attributes.value(forKey: "binaryData") as? Data, testData)
        XCTAssertEqual(attributes.value(forKey: "transformable") as? String, nil)
        XCTAssertEqual(attributes.value(forKey: "customTransformerString") as! String, "Foo & bar")
        XCTAssertEqual(attributes.value(forKey: "uuid") as? UUID, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"))
        XCTAssertEqual(attributes.value(forKey: "uri") as? URL, URL(string: "https://www.apple.com/"))
        
    }
    
    
    func testFillManagedObjectWithDictionary() {
        let values: [String: Any] = ["first_name" : "Jane", "last_name" : "Sid"]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        XCTAssertEqual(user.value(forKey: "firstName") as! String, values["first_name"] as! String)
    }
             
    func testUpdateExistingValueWithNull() {
        let values = ["first_name" : "Jane", "last_name" : "Sid"]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        let updatedValues = ["first_name" : nil, "last_name" : "Sid"]
        user.hyp_fill(with: updatedValues)
        
        XCTAssertNil(user.value(forKey: "firstName"))
    }
    
    func testAgeNumber() {
        let values = ["age" : 24]
        
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        XCTAssertEqual(user.value(forKey: "age") as? Int, values["age"]!)
    }
    
    func testAgeString() {
        let values = ["age" : "24"]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        let formatter = NumberFormatter()
        let age = formatter.number(from: values["age"]!)
        
        XCTAssertEqual(user.value(forKey: "age") as? NSNumber, age)
        
    }
    
    
    func testBornDate() {
        let values = ["birth_date" : "1989-02-14T00:00:00+00:00"]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let date = dateFormatter.date(from: "1989-02-14")
        
        XCTAssertEqual(user.value(forKey: "birthDate") as? Date, date)
    }
    
    func testUpdate() {
        let values = ["first_name" : "Jane", "last_name" : "Sid", "age" : 30] as [String : Any]
        let user = userUsingContainer(container)
        
        user.hyp_fill(with: values)
        
        let updatedValues = ["first_name" : "Jeanet"]
        user.hyp_fill(with: updatedValues)
        
        XCTAssertEqual(user.value(forKey: "firstName") as? String, updatedValues["first_name"]!)
        XCTAssertEqual(user.value(forKey: "lastName") as? String, values["last_name"] as? String)
    }
    
    func testUpdateIgnoringEqualValues() {
        let values = ["first_name" : "Jane", "last_name" : "Sid", "age" : 30] as [String : Any]
        let user = userUsingContainer(container)
        
        user.hyp_fill(with: values)
        
        do {
         try user.managedObjectContext?.save()
        } catch {
            print("!!!!!!!!!!!!")
        }

        let updatedValues = ["first_name" : "Jane", "last_name" : "Sid", "age" : 30] as [String : Any]
        user.hyp_fill(with: updatedValues)

        // TODO: Has changes
        // XCTAssertFalse(user.hasChanges)
    }
    
    func testAcronyms() {
        let values = ["contract_id" : 100]
        let user = userUsingContainer(container)
        
        user.hyp_fill(with: values)
        
        XCTAssertEqual(user.value(forKey: "contractID") as! Int, 100)
    }

    
    func testArrayStorage() {
        let values = ["hobbies" : ["football", "soccer", "code"]]
        let user = userUsingContainer(container)
        
        user.hyp_fill(with: values)
        
        XCTAssertEqual(NSKeyedArchiver.unarchiveArray(from: user.value(forKey: "hobbies") as? Data)?[0] as! String, "football")
        XCTAssertEqual(NSKeyedArchiver.unarchiveArray(from: user.value(forKey: "hobbies") as? Data)?[1] as! String, "soccer")
        XCTAssertEqual(NSKeyedArchiver.unarchiveArray(from: user.value(forKey: "hobbies") as? Data)?[2] as! String, "code")
        
    }
    
    func testDictionaryStorage() {
        let values = ["expenses" : ["cake" : 12.50, "juice" : 0.50]]
        let user = userUsingContainer(container)
        
        user.hyp_fill(with: values)
        
        XCTAssertEqual(NSKeyedArchiver.unarchiveDictionary(from: user.value(forKey: "expenses") as? Data)?["cake"] as? Double, 12.50)
        XCTAssertEqual(NSKeyedArchiver.unarchiveDictionary(from: user.value(forKey: "expenses") as? Data)?["juice"] as? Double, 0.50)
        
    }
    
    
    func testReservedWords() {
        let values = ["id" : 100, "description" : "This is the description", "type" : "user type"] as [String : Any]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        XCTAssertEqual(user.value(forKey: "remoteID") as? Int, 100)
        XCTAssertEqual(user.value(forKey: "userDescription") as? String, "This is the description")
        XCTAssertEqual(user.value(forKey: "userType") as? String, "user type")
    }
    
    func testCreatedAt() {
        let values = ["created_at" : "2014-01-01T00:00:00+00:00",
                      "updated_at" : "2014-01-02",
                      "number_of_attendes" : 20] as [String : Any]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        let createdAt = dateFormat.date(from: "2014-01-01")
        let updatedAt = dateFormat.date(from: "2014-01-02")
        
        XCTAssertEqual(user.value(forKey: "createdAt") as? Date, createdAt)
        XCTAssertEqual(user.value(forKey: "updatedAt") as? Date, updatedAt)
        XCTAssertEqual(user.value(forKey: "numberOfAttendes") as? Int, 20)
    }
    
    func testCustomRemoteKeys() {
        let values = ["age_of_person" : 20, "driver_identifier_str" : "123", "signed" : "salesman"] as [String : Any]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        XCTAssertEqual(user.value(forKey: "age") as? Int, 20)
        XCTAssertEqual(user.value(forKey: "driverIdentifier") as? String, "123")
        XCTAssertEqual(user.value(forKey: "rawSigned") as? String, "salesman")
    }
    
    func testIgnoredTranformables() {
        let values = ["ignoreTransformable" : "I'm going to be ignored"]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        XCTAssertEqual(user.value(forKey: "ignoreTransformable") as? String, nil)
    }
    
    func testRegisteredTransformables() {
        DateStringTransformer.register()
        
        let values = ["registeredTransformable" : "/Date(1451606400000)/"]
        let user = userUsingContainer(container)
        user.hyp_fill(with: values)
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        let date = dateFormat.date(from: "2016-01-01")
        
        XCTAssertNotNil(user.value(forKey: "registeredTransformable"))
        XCTAssertEqual(user.value(forKey: "registeredTransformable") as? Date, date)
        XCTAssertTrue(user.value(forKey: "registeredTransformable") is Date)
    }
    
    func testCustomKey() {
        let values = ["id" : "1", "other_attribute" : "Market 1"]
        let market: NSManagedObject = self.entityNamed("Market", inContext: container.viewContext) as! NSManagedObject
        market.hyp_fill(with: values)
        
        XCTAssertEqual(market.value(forKey: "uniqueId") as? String, "1")
        XCTAssertEqual(market.value(forKey: "otherAttribute") as? String, "Market 1")
    }
    
    func testCustomKeyPathSnakeCase() {
        let values = ["snake_parent" :
                        ["value_one" : "Value 1",
                         "depth_one" : [ "depth_two" : "Value 2"]
                        ]]
        let keyPaths: NSManagedObject = self.entityNamed("KeyPath", inContext: container.viewContext) as! NSManagedObject
        keyPaths.hyp_fill(with: values)
        
        XCTAssertEqual(keyPaths.value(forKey: "snakeCaseDepthOne") as? String, "Value 1")
        XCTAssertEqual(keyPaths.value(forKey: "snakeCaseDepthTwo") as? String, "Value 2")
        
    }
    
    func testCustomKeyPathCamelCase() {
        let values = ["camelParent" : ["valueOne" : "Value 1", "depthOne" : ["depthTwo" : "Value 2"]]]
        let keyPaths: NSManagedObject = self.entityNamed("KeyPath", inContext: container.viewContext) as! NSManagedObject
        
        keyPaths.hyp_fill(with: values)
        
        XCTAssertEqual(keyPaths.value(forKey: "camelCaseDepthOne") as? String, "Value 1")
        XCTAssertEqual(keyPaths.value(forKey: "camelCaseDepthTwo") as? String, "Value 2")
    }
}




// MARK: Extensions

extension NSKeyedArchiver  {
    
    class func unarchiveArray(from data: Data?) -> Array<Any?>? {
        var array: NSArray? = nil
        do {
            if let data = data {
               // array = try NSKeyedUnarchiver.unarchivedObject(ofClass: Array.self, from: data)
                array = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data)
            }
        } catch let unarchivingError {
            print("NSKeyedUnarchiver (Sync) unarchivingError \(unarchivingError.localizedDescription)")
        }
        return array as? Array<Any?>
    }

    class func unarchiveDictionary(from data: Data?) -> [AnyHashable: Any]?  {
        var dictionary: NSDictionary? = nil
        do {
            if let data = data {
                dictionary = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data)
            }
        } catch let unarchivingError {
            print("NSKeyedUnarchiver (Sync) unarchivingError \(unarchivingError.localizedDescription)")
        }
        return dictionary as? [AnyHashable : Any]
    }
    
}



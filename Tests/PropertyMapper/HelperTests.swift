//
//  File.swift
//  
//
//  Created by Lee Avery on 19/01/2022.
//


import Foundation
import XCTest
import CoreData
import Sync

class PrivateTests: XCTestCase {
    
    func entityNamed(_ entityName: String) -> NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext())
    }
    
    func managedObjectContext() -> NSManagedObjectContext {
        let dataStack: DataStack = Helper.dataStackWithModelName("Model")
        return dataStack.mainContext
    }
    
    func testAttributeDescriptionForKeyA() {
        let company: NSManagedObject = self.entityNamed("Company")
        var attributeDescription: NSAttributeDescription
        
        attributeDescription = company.attributeDescriptionForRemoteKey("name")!
        XCTAssertEqual(attributeDescription.name, "name")
        
        attributeDescription = company.attributeDescriptionForRemoteKey("id")!
        XCTAssertEqual(attributeDescription.name, "remoteID")
    }
    
    func testAttributeDescriptionForKeyB() {
        let market = self.entityNamed("Market")
        var attributeDescription: NSAttributeDescription
        
        attributeDescription = market.attributeDescriptionForRemoteKey("id")!
        XCTAssertEqual(attributeDescription.name, "uniqueId")
        
        attributeDescription = market.attributeDescriptionForRemoteKey("other_attribute")!
        XCTAssertEqual(attributeDescription.name, "otherAttribute")
    }
    
    func testAttributeDescriptionForKeyC() {
        let user = self.entityNamed("User")
        var attributeDescription: NSAttributeDescription?

        attributeDescription = user.attributeDescriptionForRemoteKey("age_of_person")
        XCTAssertEqual(attributeDescription?.name, "age")

        attributeDescription = user.attributeDescriptionForRemoteKey("driver_identifier_str")
        XCTAssertEqual(attributeDescription?.name, "driverIdentifier")

        attributeDescription = user.attributeDescriptionForRemoteKey("not_found_key")
        XCTAssertNil(attributeDescription)
    }

    func testAttributeDescriptionForKeyD() {
        let keyPath = self.entityNamed("KeyPath")
        var attributeDescription: NSAttributeDescription

        attributeDescription = keyPath.attributeDescriptionForRemoteKey("snake_parent.value_one")!
        XCTAssertEqual(attributeDescription.name, "snakeCaseDepthOne")

        attributeDescription = keyPath.attributeDescriptionForRemoteKey("snake_parent.depth_one.depth_two")!
        XCTAssertEqual(attributeDescription.name, "snakeCaseDepthTwo")

        attributeDescription = keyPath.attributeDescriptionForRemoteKey("camelParent.valueOne")!
        XCTAssertEqual(attributeDescription.name, "camelCaseDepthOne")

        attributeDescription = keyPath.attributeDescriptionForRemoteKey("camelParent.depthOne.depthTwo")!
        XCTAssertEqual(attributeDescription.name, "camelCaseDepthTwo")
    }

    func testAttributeDescriptionForKeyCompatibility() {
        let keyPath = self.entityNamed("Compatibility")
        var attributeDescription: NSAttributeDescription

        attributeDescription = keyPath.attributeDescriptionForRemoteKey("customCurrent")!
        XCTAssertEqual(attributeDescription.name, "current")

        attributeDescription = keyPath.attributeDescriptionForRemoteKey("customOld")!
        XCTAssertEqual(attributeDescription.name, "old")
    }

    func testRemoteKeyForAttributeDescriptionA() {
        let company = self.entityNamed("Company")
        var attributeDescription: NSAttributeDescription?
        let holdingDictionary = company.entity.propertiesByName

        attributeDescription = holdingDictionary["name"] as? NSAttributeDescription
        XCTAssertEqual(company.remoteKeyForAttributeDescription(attributeDescription!), "name")

        attributeDescription = holdingDictionary["remoteID"] as? NSAttributeDescription
        XCTAssertEqual(company.remoteKeyForAttributeDescription(attributeDescription!), "id")
    }

    func testRemoteKeyForAttributeDescriptionB() {
        let market = self.entityNamed("Market")
        var attributeDescription: NSAttributeDescription
        
        let holdingDictionary = market.entity.propertiesByName
        attributeDescription = holdingDictionary["uniqueId"] as! NSAttributeDescription
        XCTAssertEqual(market.remoteKeyForAttributeDescription(attributeDescription), "id")

        attributeDescription = holdingDictionary["otherAttribute"] as! NSAttributeDescription
        XCTAssertEqual(market.remoteKeyForAttributeDescription(attributeDescription), "other_attribute")
    }

    func testRemoteKeyForAttributeDescriptionC() {
        let user = self.entityNamed("User")
        var attributeDescription: NSAttributeDescription

        let holdingDictionary = user.entity.propertiesByName
        attributeDescription = holdingDictionary["age"] as! NSAttributeDescription
        XCTAssertEqual(user.remoteKeyForAttributeDescription(attributeDescription), "age_of_person")

        attributeDescription = holdingDictionary["driverIdentifier"] as! NSAttributeDescription
        XCTAssertEqual(user.remoteKeyForAttributeDescription(attributeDescription), "driver_identifier_str")

        //XCTAssertNil(user.remoteKeyForAttributeDescription(nil))
    }

    func testRemoteKeyForAttributeDescriptionD() {
        let keyPath = self.entityNamed("KeyPath")
        var attributeDescription: NSAttributeDescription

        let holdingDictionary = keyPath.entity.propertiesByName

        attributeDescription = holdingDictionary["snakeCaseDepthOne"] as! NSAttributeDescription
        XCTAssertEqual(keyPath.remoteKeyForAttributeDescription(attributeDescription), "snake_parent.value_one")

        attributeDescription = holdingDictionary["snakeCaseDepthTwo"] as! NSAttributeDescription
        XCTAssertEqual(keyPath.remoteKeyForAttributeDescription(attributeDescription), "snake_parent.depth_one.depth_two")

        attributeDescription = holdingDictionary["camelCaseDepthOne"] as! NSAttributeDescription
        XCTAssertEqual(keyPath.remoteKeyForAttributeDescription(attributeDescription), "camelParent.valueOne")

        attributeDescription = holdingDictionary["camelCaseDepthTwo"] as! NSAttributeDescription
        XCTAssertEqual(keyPath.remoteKeyForAttributeDescription(attributeDescription), "camelParent.depthOne.depthTwo")
    }

    func testDestroyKey() {
        let note = self.entityNamed("Note")
        var attributeDescription: NSAttributeDescription
        let holdingDictionary = note.entity.propertiesByName
        
        attributeDescription = holdingDictionary["destroy"] as! NSAttributeDescription
        XCTAssertEqual(note.remoteKeyForAttributeDescription(attributeDescription), "_destroy")

        attributeDescription = holdingDictionary["destroy"] as! NSAttributeDescription
        XCTAssertEqual(note.remoteKeyForAttributeDescription(attributeDescription, usingRelationshipType: .array), "destroy")
    }

    
}

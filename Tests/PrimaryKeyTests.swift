//
//  File.swift
//  
//
//  Created by Lee Avery on 22/01/2022.
//

import Foundation
import XCTest
import CoreData
import Sync

class PrimaryKeyTests : XCTestCase {
    
    func entityForName(_ name: String) -> NSEntityDescription {
        let dataStack = Helper.dataStackWithModelName("PrimaryKey")
        return NSEntityDescription.entity(forEntityName: name, in: dataStack.mainContext)!
    }
    
    
    func testPrimaryKeyAttribute() {
        var entity: NSEntityDescription? = self.entityForName("User")
        
        var attribute: NSAttributeDescription? = entity?.sync_primaryKeyAttribute()
        XCTAssertEqual(attribute?.attributeValueClassName, "NSNumber")
        XCTAssertEqual(attribute?.attributeType, NSAttributeType.integer32AttributeType)
        
        entity = self.entityForName("SimpleID")
        attribute = entity?.sync_primaryKeyAttribute()
        XCTAssertEqual(attribute?.attributeValueClassName, "NSString")
        XCTAssertEqual(attribute?.attributeType, NSAttributeType.stringAttributeType)
        XCTAssertEqual(attribute?.name, "id")
        
        entity = self.entityForName("Note")
        attribute = entity?.sync_primaryKeyAttribute()
        XCTAssertEqual(attribute?.attributeValueClassName, "NSNumber")
        XCTAssertEqual(attribute?.attributeType, NSAttributeType.integer16AttributeType)
        XCTAssertEqual(attribute?.name, "uniqueID")
        
        entity = self.entityForName("Tag")
        attribute = entity?.sync_primaryKeyAttribute()
        XCTAssertEqual(attribute?.attributeValueClassName, "NSString")
        XCTAssertEqual(attribute?.attributeType, NSAttributeType.stringAttributeType)
        XCTAssertEqual(attribute?.name, "randomId")
        
        entity = self.entityForName("NoID")
        attribute = entity?.sync_primaryKeyAttribute()
        XCTAssertNil(attribute)
        
        entity = self.entityForName("AlternativeID")
        attribute = entity?.sync_primaryKeyAttribute()
        XCTAssertEqual(attribute?.attributeValueClassName, "NSString")
        XCTAssertEqual(attribute?.attributeType, NSAttributeType.stringAttributeType)
        XCTAssertEqual(attribute?.name, "alternativeID")
    }
    
    
    func testLocalPrimaryKey() {
        var entity: NSEntityDescription? = self.entityForName("User")
        XCTAssertEqual(entity?.sync_localPrimaryKey(), "remoteID")
        
        entity = self.entityForName("SimpleID")
        XCTAssertEqual(entity?.sync_localPrimaryKey(), "id")
        
        entity = self.entityForName("Note")
        XCTAssertEqual(entity?.sync_localPrimaryKey(), "uniqueID")

        entity = self.entityForName("Tag")
        XCTAssertEqual(entity?.sync_localPrimaryKey(), "randomId")

        entity = self.entityForName("NoID")
        XCTAssertNil(entity?.sync_localPrimaryKey())

        entity = self.entityForName("AlternativeID")
        XCTAssertEqual(entity?.sync_localPrimaryKey(), "alternativeID")

        entity = self.entityForName("Compatibility")
        XCTAssertEqual(entity?.sync_localPrimaryKey(), "custom")
    }
    
    func testRemotePrimaryKey() {
        var entity: NSEntityDescription? = self.entityForName("User")
        XCTAssertEqual(entity?.sync_remotePrimaryKey(), "id")
        
        entity = self.entityForName("SimpleID")
        XCTAssertEqual(entity?.sync_remotePrimaryKey(), "id")
        
        entity = self.entityForName("Note")
        XCTAssertEqual(entity?.sync_remotePrimaryKey(), "unique_id")

        entity = self.entityForName("Tag")
        XCTAssertEqual(entity?.sync_remotePrimaryKey(), "id")

        entity = self.entityForName("NoID")
        XCTAssertNil(entity?.sync_remotePrimaryKey())

        entity = self.entityForName("AlternativeID")
        XCTAssertEqual(entity?.sync_remotePrimaryKey(), "alternative_id")

        entity = self.entityForName("Compatibility")
        XCTAssertEqual(entity?.sync_remotePrimaryKey(), "greeting")
    }
}

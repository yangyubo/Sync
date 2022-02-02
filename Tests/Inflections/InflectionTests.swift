//
//  File.swift
//  
//
//  Created by Lee Avery on 19/01/2022.
//

import XCTest
import Foundation
import Sync

class NSString_InflectionsTests : XCTestCase {
    
    func testReplacementIdentifier() {
        var testString = "first_name"
        
        XCTAssertEqual(testString.hyp_replaceIdentifierWithString(""), "FirstName")
        
        testString = "id"
        
        XCTAssertEqual(testString.hyp_replaceIdentifierWithString(""), "ID")
        
        testString = "user_id"
        
        XCTAssertEqual(testString.hyp_replaceIdentifierWithString(""), "UserID")
    }
    
    func testLowerCaseFirstLetter() {
        let testString = "FirstName"
        
        XCTAssertEqual(testString.hyp_lowerCaseFirstLetter(), "firstName")
    }
    
    func testSnakeCase() {
        var camelCase = "age"
        var snakeCase = "age"
        
        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())
        
        camelCase = "id"
        snakeCase = "id"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "pdf"
        snakeCase = "pdf"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "driverIdentifier"
        snakeCase = "driver_identifier"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "integer16"
        snakeCase = "integer16"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "userID"
        snakeCase = "user_id"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "createdAt"
        snakeCase = "created_at"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "userIDFirst"
        snakeCase = "user_id_first"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "OrderedUser"
        snakeCase = "ordered_user"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "iUUID"
        snakeCase = "i_uuid"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "iURI"
        snakeCase = "i_uri"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())

        camelCase = "iURL"
        snakeCase = "i_url"

        XCTAssertEqual(snakeCase, camelCase.hyp_snakeCase())
    }
    
    
    func testCamelCase() {
        var snakeCase: String = "age"
        var camelCase: String = "age"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "id"
        camelCase = "id"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "pdf"
        camelCase = "pdf"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "uuid"
        camelCase = "uuid"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "driver_identifier"
        camelCase = "driverIdentifier"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "integer16"
        camelCase = "integer16"

        XCTAssertEqual(snakeCase, camelCase.hyp_camelCase())

        snakeCase = "user_id"
        camelCase = "userID"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "updated_at"
        camelCase = "updatedAt"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "updated_uuid"
        camelCase = "updatedUUID"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "updated_uri"
        camelCase = "updatedURI"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "updated_url"
        camelCase = "updatedURL"

        XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

    //    snakeCase = "f2f_url"
    //    camelCase = "f2fURL"
    //
    //    XCTAssertEqual(camelCase, snakeCase.hyp_camelCase())

        snakeCase = "test_!_key"
        XCTAssertNil(snakeCase.hyp_camelCase())
    }
    
    func testCamleCaseCapitalizedString() {
        let capitalizedString = "GreenWallet"
        let camelCase = "greenWallet"
        
        XCTAssertEqual(camelCase, capitalizedString.hyp_camelCase())
    }
    
    func testStorageForSameWordButDifferentInflections() {
        XCTAssertEqual("greenWallet", "GreenWallet".hyp_camelCase())
        XCTAssertEqual("green_wallet", "GreenWallet".hyp_snakeCase())
    }
    
}


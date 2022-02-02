//
//  File.swift
//  
//
//  Created by Lee Avery on 19/01/2022.
//

import Foundation

class SyncTestValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if (value == nil) { return nil }
        
        var stringValue: String? = nil
        
        if (value is String) {
            stringValue = (value as! String)
        } else {
            assertionFailure("value \(String(describing: value.self)) is not of type String", file: "SyncTestValueTransformer", line: 25)
        }
        return stringValue?.replacingOccurrences(of: "&amp;", with: "&")
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if (value == nil) { return nil }
        
        var stringValue: String? = nil
        
        if (value is String) {
            stringValue = value as? String
        } else {
            assertionFailure("value \(String(describing: value.self)) is not of type String", file: "SyncTestValueTransformer", line: 38)
        }
        return stringValue?.replacingOccurrences(of: "&", with: "&amp;")
    }
}

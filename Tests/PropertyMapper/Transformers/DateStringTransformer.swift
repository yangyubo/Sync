//
//  File.swift
//  
//
//  Created by Lee Avery on 19/01/2022.
//

import Foundation


class DateStringTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass{
        return NSDate.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if (value is String) {
            let intStr = ((value as! String).replacingOccurrences(of: "/Date", with: "")).replacingOccurrences(of: ")/", with: "")
            let timestampMS = Int(intStr) ?? 0
            let timestamp = Double(timestampMS) / 1000.0
            let date = Date(timeIntervalSince1970: timestamp)
            return date
        } else {
            return value
        }
    }
}

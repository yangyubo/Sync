//
//  File.swift
//  
//
//  Created by Lee Avery on 14/01/2022.
//

import Foundation
import CoreData



let SyncCustomLocalPrimaryKey = "sync.isPrimaryKey"
let SyncCompatibilityCustomLocalPrimaryKey = "hyper.isPrimaryKey"
let SyncCustomLocalPrimaryKeyValue = "YES"
let SyncCustomLocalPrimaryKeyAlternativeValue = "true"

let SyncCustomRemoteKey = "sync.remoteKey"
let SyncCompatibilityCustomRemoteKey = "hyper.remoteKey"

let PropertyMapperNonExportableKey = "sync.nonExportable"
let PropertyMapperCompatibilityNonExportableKey = "hyper.nonExportable"

let PropertyMapperCustomValueTransformerKey = "sync.valueTransformer"
let PropertyMapperCompatibilityCustomValueTransformerKey = "hyper.valueTransformer"

public extension NSPropertyDescription {
    
    func isCustomPrimaryKey() -> Bool {
        var keyName: String?  = self.userInfo![SyncCustomLocalPrimaryKey] as? String
        if (keyName == nil) {
            keyName = self.userInfo![SyncCompatibilityCustomLocalPrimaryKey] as? String
        }
        let hasCustomPrimaryKey = ((keyName != nil) && (keyName == SyncCustomLocalPrimaryKeyValue || keyName == SyncCustomLocalPrimaryKeyAlternativeValue))

        return hasCustomPrimaryKey
    }
    
    
    func customKey() -> String? {
        var keyName: String? = self.userInfo?[SyncCustomRemoteKey] as? String
        if (keyName == nil) {
            keyName = self.userInfo?[SyncCompatibilityCustomRemoteKey] as? String
        }

        return keyName
    }
    
    
    func shouldExportAttribute() -> Bool {
        var nonExportableKey = self.userInfo![PropertyMapperNonExportableKey] as? String
        if (nonExportableKey == nil) {
            nonExportableKey = self.userInfo![PropertyMapperCompatibilityNonExportableKey] as? String
        }
        
        let shouldExportAttribute = (nonExportableKey == nil)
        return shouldExportAttribute
    }
    
    
    func customTransformerName() -> String? {
        var keyName = self.userInfo![PropertyMapperCustomValueTransformerKey] as? String
        if (keyName == nil) {
            keyName = self.userInfo![PropertyMapperCompatibilityCustomValueTransformerKey] as? String
        }
        
        return keyName
    }
}

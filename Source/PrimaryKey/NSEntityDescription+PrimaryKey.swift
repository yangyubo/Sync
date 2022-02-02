//
//  File.swift
//  
//
//  Created by Lee Avery on 12/01/2022.
//

import Foundation
import CoreData

let SyncDefaultLocalPrimaryKey = "id"
let SyncDefaultLocalCompatiblePrimaryKey = "remoteID"
let SyncDefaultRemotePrimaryKey = "id"

public extension NSEntityDescription {

    /**
     Returns the Core Data attribute used as the primary key. By default it will look for the attribute named `id`.
     You can mark any attribute as primary key by adding `sync.isPrimaryKey` and the value `YES` to the Core Data model userInfo.

     - returns:
     The attribute description that represents the primary key.
     */
    func sync_primaryKeyAttribute() -> NSAttributeDescription? {
        var primaryKeyAttribute: NSAttributeDescription?
        
        for (key, attributeDescription) in (propertiesByName as NSDictionary) {
            var stop = false
            let attributeDescription = (attributeDescription as? NSAttributeDescription)
            if attributeDescription != nil && attributeDescription!.isCustomPrimaryKey() {
                primaryKeyAttribute = attributeDescription!
                stop = true
            }
            
            if(key as! String == SyncDefaultLocalPrimaryKey || key as! String == SyncDefaultLocalCompatiblePrimaryKey) {
                primaryKeyAttribute = attributeDescription
            }
            if stop {break}
        }
        return primaryKeyAttribute
    }
    
    
    /**
     Returns the local primary key for the entity.

     - returns:
     The name of the attribute that represents the local primary key;.
     */
    func sync_localPrimaryKey() -> String? {
        let primaryAttribute = self.sync_primaryKeyAttribute()
        return primaryAttribute?.name
    }
    
    /**
     Returns the remote primary key for the entity.

     - returns:
     The name of the attribute that represents the remote primary key.
     */
    func sync_remotePrimaryKey() -> String? {
        let primaryKeyAttribute = sync_primaryKeyAttribute()
        var remoteKey = primaryKeyAttribute?.customKey()

        if (remoteKey == nil) {
            if (primaryKeyAttribute?.name == SyncDefaultLocalPrimaryKey) || (primaryKeyAttribute?.name == SyncDefaultLocalCompatiblePrimaryKey) {
                remoteKey = SyncDefaultRemotePrimaryKey

            } else {
                remoteKey = primaryKeyAttribute?.name.hyp_snakeCase()

            }
        }

        return remoteKey
    }
}

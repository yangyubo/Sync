//
//  File.swift
//  
//
//  Created by Lee Avery on 13/01/2022.
//

import Foundation
import CoreData


let PropertyMapperDestroyKey = "destroy"

public extension NSManagedObject {
        
    func valueForAttributeDescription(
        _ attributeDescription: NSAttributeDescription,
        dateFormatter: DateFormatter,
        relationshipType: SyncPropertyMapperRelationshipType) -> Any? {
            
            var value: Any?
            if (attributeDescription.attributeType != .transformableAttributeType) {
                value = self.value(forKey: attributeDescription.name)
                let nilOrNullValue = (value == nil) || (value is NSNull)
                let customTranformerName: String? = attributeDescription.customTransformerName()
                
                if nilOrNullValue {
                    value = NSNull()
                } else if (value is Date) {
                    value = dateFormatter.string(from: (value as! Date))
                } else if (value is UUID) {
                    value = (value as! UUID).uuidString
                } else if (value is NSURL) {
                    value = (value as! URL).absoluteString
                } else if (customTranformerName != nil) {
                    let transformer = ValueTransformer(forName: NSValueTransformerName(rawValue: customTranformerName!))
                    if let transformer = transformer {
                        value = transformer.reverseTransformedValue(value)
                    }
                }
            } else if attributeDescription.attributeType == .transformableAttributeType {
                value = self.value(forKey:attributeDescription.name)
            }
            return value
        }
    
    func attributeDescriptionForRemoteKey(_ remoteKey: String) -> NSAttributeDescription? {
        return self.attributeDescriptionForRemoteKey(remoteKey, usingInflectionType: .snakeCase)
    }
    
    func attributeDescriptionForRemoteKey(_ remoteKey: String, usingInflectionType inflectionType: SyncPropertyMapperInflectionType) -> NSAttributeDescription? {
        
        var foundAttributeDescription: NSAttributeDescription?
        
        for propertyDescription in self.entity.properties {
            var stop = false
            if (propertyDescription is NSAttributeDescription) {
                let attributeDescription: NSAttributeDescription = propertyDescription as! NSAttributeDescription
                let customRemoteKey = entity.propertiesByName[attributeDescription.name]!.customKey() ?? ""
                
                let currentAttributeHasTheSameRemoteKey = (customRemoteKey.count > 0) && (customRemoteKey == remoteKey)
                if currentAttributeHasTheSameRemoteKey {
                    foundAttributeDescription = attributeDescription
                   stop = true
                }
                
                let customRootRemoteKey = customRemoteKey.components(separatedBy: ".").first ?? ""
                let currentAttributeHasTheSameRootRemoteKey = ((customRootRemoteKey.count > 0) && (customRootRemoteKey == remoteKey))
                if (currentAttributeHasTheSameRootRemoteKey) {
                    foundAttributeDescription = attributeDescription
                    stop = true
                }
                
                if (attributeDescription.name == remoteKey) {
                    foundAttributeDescription = attributeDescription
                    stop = true
                }
                
                var localKey = remoteKey.hyp_camelCase()
                if reservedAttributes().contains(remoteKey) {
                    let prefixedRemoteKey = self.prefixedAttribute(remoteKey, usingInflectionType: inflectionType)
                    localKey = prefixedRemoteKey.hyp_camelCase()
                }
                
                if (attributeDescription.name == localKey) {
                    foundAttributeDescription = attributeDescription
                    stop = true
                }
            }
            if stop { break}
        }
        
        if (foundAttributeDescription == nil) {
            for propertyDescription in entity.properties {
                var stop = false
                if (propertyDescription is NSAttributeDescription) {
                    let attributeDescription: NSAttributeDescription = propertyDescription as! NSAttributeDescription
                    
                    if (remoteKey == SyncDefaultRemotePrimaryKey) && ((attributeDescription.name == SyncDefaultLocalPrimaryKey) || (attributeDescription.name == SyncDefaultLocalCompatiblePrimaryKey)) {
                        foundAttributeDescription = (self.entity.propertiesByName[attributeDescription.name] as! NSAttributeDescription)
                    }
                    
                    if (foundAttributeDescription != nil) {
                        stop = true
                    }
                }
                if stop {break}
            }
        }
        return foundAttributeDescription
    }
    
    
    
    func attributeDescriptionsForRemoteKeyPath(_ remoteKey: String) -> Array<NSAttributeDescription> {
        var foundAttributeDescriptions: Array<NSAttributeDescription> = Array()
        
        for propertyDescription in entity.properties {
            if (propertyDescription is NSAttributeDescription) {
                let attributeDescription = propertyDescription as! NSAttributeDescription
                
                let customRemoteKeyPath: String = self.entity.propertiesByName[attributeDescription.name]!.customKey() ?? ""
                let customRootRemoteKey: String = customRemoteKeyPath.components(separatedBy: ".").first ?? ""
                let rootRemoteKey = remoteKey.components(separatedBy: ".").first
                
                if ((customRootRemoteKey.count > 0) && (customRootRemoteKey == rootRemoteKey)) {
                    foundAttributeDescriptions.append(attributeDescription)
                }
            }
        }
        return foundAttributeDescriptions
    }
    
    
    func remoteKeyForAttributeDescription(_ attributeDescription: NSAttributeDescription) -> String {
        return self.remoteKeyForAttributeDescription(attributeDescription, usingRelationshipType: .nested, inflectionType: .snakeCase)
    }
    
    func remoteKeyForAttributeDescription(_ attributeDescription: NSAttributeDescription, inflectionType: SyncPropertyMapperInflectionType) -> String {
        return self.remoteKeyForAttributeDescription(attributeDescription, usingRelationshipType: .nested, inflectionType: inflectionType)
    }
    
    func remoteKeyForAttributeDescription(_ attributeDescription: NSAttributeDescription, usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> String {
        return self.remoteKeyForAttributeDescription(attributeDescription, usingRelationshipType: relationshipType, inflectionType: .snakeCase)
    }
    
    
    func remoteKeyForAttributeDescription(_ attributeDescription: NSAttributeDescription, usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType, inflectionType: SyncPropertyMapperInflectionType) -> String {
        let localKey = attributeDescription.name
        let customRemoteKey = attributeDescription.customKey()
        var remoteKey: String?
        
        if (customRemoteKey != nil) {
            remoteKey = customRemoteKey
        } else if (localKey == SyncDefaultLocalPrimaryKey) || (localKey == SyncDefaultLocalCompatiblePrimaryKey) {
            remoteKey = SyncDefaultRemotePrimaryKey
        } else if (localKey == PropertyMapperDestroyKey) && (relationshipType == .nested) {
            remoteKey = "_" + PropertyMapperDestroyKey
        } else {
            switch (inflectionType) {
            case .snakeCase :
                remoteKey = localKey.hyp_snakeCase()
            case .camelCase :
                remoteKey = localKey
            }
        }
        
        let isReservedKey = self.reservedKeysUsingInflectionType(inflectionType).contains(remoteKey ?? "")
        if isReservedKey {
            var prefixedKey: String = remoteKey!
            prefixedKey = prefixedKey.replacingOccurrences(of: self.remotePrefixUsingInflectionType(inflectionType), with: "")
            remoteKey = prefixedKey
            if (inflectionType == .camelCase) {
                remoteKey = remoteKey!.hyp_camelCase()
            }
        }
        return remoteKey ?? ""
    }
    
    

    func valueForAttributeDescription(_ attributeDescription: NSAttributeDescription, usingRemoteValue remoteValue: Any) -> Any {
        var value: Any?
        
        let attributedClass: AnyClass? = NSClassFromString(attributeDescription.attributeValueClassName ?? "")
        if (attributedClass == NSString.self) && (remoteValue is String) { value = remoteValue }
        if (attributedClass == NSNumber.self) && (remoteValue is NSNumber) { value = remoteValue }
        if (attributedClass == NSUUID.self) && (remoteValue is NSUUID) {value = remoteValue}
        
        let customTransformerName: String? = attributeDescription.customTransformerName()
        if customTransformerName != nil {
            let transformer = ValueTransformer(forName: NSValueTransformerName(customTransformerName!))
            if transformer != nil {
                value = transformer!.transformedValue(remoteValue)
            }
        }
        let stringValueAndNumberAttribute = (remoteValue is NSString) && (attributedClass == NSNumber.self)
        let numberValueAndStringAttribute = (remoteValue is NSNumber) && (attributedClass == NSString.self)
        let stringValueAndDateAttribute = (remoteValue is NSString) && (attributedClass == NSDate.self)
        let numberValueAndDateAttribute = (remoteValue is NSNumber) && (attributedClass == NSDate.self)
        let stringValueAndUUIDAttribute = (remoteValue is NSString) && (attributedClass == NSUUID.self)
        let stringValueAndURIAttribute = (remoteValue is NSString) && (attributedClass == NSURL.self)
        let dataAttribute = (attributedClass == NSData.self)
        let numberValueAndDecimalAttribute = (remoteValue is NSNumber) && (attributedClass == NSDecimalNumber.self)
        let stringValueAndDecimalAttribute = (remoteValue is NSString) && (attributedClass == NSDecimalNumber.self)
        let transformableAttribute = ((attributedClass == nil) && (attributeDescription.valueTransformerName != nil) && value == nil)
   
        
        if stringValueAndNumberAttribute {
            let formatter = NumberFormatter()
            formatter.locale = NSLocale(localeIdentifier: "en_US") as Locale
            value = formatter.number(from: (remoteValue as! String))
        } else if numberValueAndStringAttribute {
            value = "\(remoteValue)"
        } else if stringValueAndDateAttribute {
            value = Date.fromDateString(remoteValue as! String)
        } else if numberValueAndDateAttribute {
            value = Date.fromUnixTimestampNumber(remoteValue as! Double)
        } else if stringValueAndUUIDAttribute {
            value = UUID(uuidString: (remoteValue as! String))
        } else if stringValueAndURIAttribute {
            value = URL(string: (remoteValue as! String))
        } else if dataAttribute {
            do {
                value = try NSKeyedArchiver.archivedData(withRootObject: remoteValue, requiringSecureCoding: false)
            } catch {
            }
        } else if numberValueAndDecimalAttribute {
            let number = remoteValue as? NSNumber
            if let decimalValue = number?.decimalValue {
                value = NSDecimalNumber(decimal: decimalValue)
            }
        } else if stringValueAndDecimalAttribute {
            value = NSDecimalNumber(string: (remoteValue as! String))
        } else if transformableAttribute {
            let transformer = ValueTransformer(forName: NSValueTransformerName(attributeDescription.valueTransformerName!))
            if transformer != nil {
                if (transformer is NSSecureUnarchiveFromDataTransformer) {
                    value = remoteValue
                } else {
                let newValue = transformer!.transformedValue(remoteValue)
                if let newValue = newValue { value = newValue }
            }
        }
        }
        
        return value as Any
    }
    
    
    func remotePrefixUsingInflectionType(_ inflectionType: SyncPropertyMapperInflectionType) -> String {
        switch inflectionType {
        case .snakeCase :
            return self.entity.name!.hyp_snakeCase() + "_"
        case .camelCase :
            return self.entity.name!.hyp_camelCase()!
        }
    }
    
    func prefixedAttribute(_ attribute: String, usingInflectionType inflectionType: SyncPropertyMapperInflectionType) -> String {
        let remotePrefix = self.remotePrefixUsingInflectionType(inflectionType)
        
        switch inflectionType {
        case .snakeCase :
            return remotePrefix + attribute
        case .camelCase :
            return remotePrefix + attribute.localizedCapitalized
        }
    }
    
    func reservedKeysUsingInflectionType(_ inflectionType: SyncPropertyMapperInflectionType) -> Array<String> {
        var keys: Array<String> = Array()
        let reservedAttributes = self.reservedAttributes()
        
        for attribute in reservedAttributes {
            keys.append(prefixedAttribute(attribute, usingInflectionType: inflectionType))
        }
        return keys
    }
    
    func reservedAttributes() -> Array<String> {
        ["type", "description", "signed"]
    }
}

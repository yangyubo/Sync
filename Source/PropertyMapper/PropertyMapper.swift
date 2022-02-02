//
//  File.swift
//  
//
//  Created by Lee Avery on 14/01/2022.
//

import Foundation
import CoreData

var PropertyMapperVersionNumber: Double = 6.0
var PropertyMapperVersionString: String = ""

public enum SyncPropertyMapperRelationshipType: Int {
    case none = 0
    case array
    case nested
}

public enum SyncPropertyMapperInflectionType: Int {
    case snakeCase = 0
    case camelCase
}

let PropertyMapperNestedAttributesKey = "attributes"

public extension NSManagedObject {
    
    func fill(with dictionary: Dictionary<String, Any?>) {
        self.hyp_fill(with: dictionary)
    }
    
    /**
     Fills the @c NSManagedObject with the contents of the dictionary using a convention-over-configuration paradigm mapping the Core Data attributes to their conterparts in JSON using snake_case.
     
     - parameters:
     - dictionary: The JSON dictionary to be used to fill the values of your @c NSManagedObject.
     */
    func hyp_fill(with dictionary: Dictionary<String, Any?>) {
        for (key, value) in dictionary {
            let attributeDescription: NSAttributeDescription?  = self.attributeDescriptionForRemoteKey(key)
            if attributeDescription != nil {
                let valueExists = (value != nil) && !(value is NSNull)
                if valueExists && (value is [String : Any?]) && attributeDescription!.attributeType != .binaryDataAttributeType {
                    let remoteKey: String? = self.remoteKeyForAttributeDescription(attributeDescription!, inflectionType: .snakeCase)
                    let hasCustomKeyPath = (remoteKey != nil) && (remoteKey!.contains("."))
                    if hasCustomKeyPath {
                        let keyPathAttributeDescriptions = attributeDescriptionsForRemoteKeyPath(remoteKey!)
                        for keyPathAttributeDescription in keyPathAttributeDescriptions {
                            let remoteKey = self.remoteKeyForAttributeDescription(keyPathAttributeDescription,
                                   inflectionType: .snakeCase)
                            let localKey = keyPathAttributeDescription.name
                            hyp_setDictionaryValue(
                                (dictionary as NSDictionary).value(forKeyPath: remoteKey),
                                forKey: localKey,
                                attributeDescription: keyPathAttributeDescription)
                        }
                    }
                } else {
                    let localKey = attributeDescription!.name
                    hyp_setDictionaryValue(
                        value,
                        forKey: localKey,
                        attributeDescription: attributeDescription)
                }
            }
        }
    }
    
    func hyp_setDictionaryValue(_ value: Any?, forKey key: String?, attributeDescription: NSAttributeDescription?) {
        let valueExists = (value != nil) && !(value is NSNull)
        if valueExists {
            let processedValue = self.valueForAttributeDescription(attributeDescription!, usingRemoteValue: value!)
            print("\(key), \(processedValue)")

            setValue(processedValue, forKey: key!)
        } else {
            setValue(nil, forKey: key!)
        }
    }
    
    
    
    
    /**
     Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Includes relationships to other models using Ruby on Rail's nested attributes model.
     @c NSDate objects will be stringified to the ISO-8601 standard.
     
     - returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary() -> Dictionary<String, Any?> {
        return hyp_dictionary(using: .snakeCase)
    }
    
    /**
     Creates a *NSDictionary * of values based on the *NSManagedObject * subclass that can be serialized by *NSJSONSerialization*. Includes relationships to other models using Ruby on Rail's nested attributes model.
     
     *NSDate* objects will be stringified to the ISO-8601 standard.
     
     - parameters:
     - inflectionType: The type used to export the dictionary, can be camelCase or snakeCase.
     
     - returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary(using inflectionType: SyncPropertyMapperInflectionType) -> Dictionary<String, Any?> {
        return hyp_dictionary(with: defaultDateFormatter(), parent: nil, using: inflectionType, andRelationshipType: .nested)
    }
    
    
    /**
     Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models.
     @c NSDate objects will be stringified to the ISO-8601 standard.
     
     - parameters:
     - relationshipType: It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
     
     - returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary(_ relationshipType: SyncPropertyMapperRelationshipType) -> Dictionary<String, Any?> {
        return hyp_dictionary(with: defaultDateFormatter(), usingRelationshipType: relationshipType)
        
    }
    
    
    /**
     Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models.
     @c NSDate objects will be stringified to the ISO-8601 standard.
     
     - parameters:
     - inflectionType: The type used to export the dictionary, can be camelCase or snakeCase.
     - relationshipType: It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
     
     - returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary(using inflectionType: SyncPropertyMapperInflectionType, andRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> Dictionary<String, Any?> {
        return hyp_dictionary(with: defaultDateFormatter(), parent: nil, using: inflectionType, andRelationshipType: relationshipType)
    }
    
    /**
     Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Includes relationships to other models using Ruby on Rail's nested attributes model.
     
     - parameters:
     + dateFormatter: A custom date formatter that turns @c NSDate objects into NSString objects. Do not pass @c nil, instead use the @c hyp_dictionary method.
     
     - returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary(with dateFormatter: DateFormatter) -> Dictionary<String, Any?> {
        return hyp_dictionary(with: dateFormatter, usingRelationshipType: .nested)
    }
    
    
    /**
     Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.
     
     - parameters:
     + dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
     + relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
     
     - returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary(with dateformatter: DateFormatter, usingRelationshipType relationshipType:SyncPropertyMapperRelationshipType) -> Dictionary<String, Any?> {
        return hyp_dictionary(with: dateformatter, parent: nil, usingRelationshipType: relationshipType)
    }
    
    
    /**
     Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.
     
     - parameters:
     - dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
     - inflectionType The type used to export the dictionary, can be camelCase or snakeCase.
     
     - returns The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary(with dateFormatter: DateFormatter, using inflectionType: SyncPropertyMapperInflectionType) -> Dictionary<String, Any?> {
        return hyp_dictionary(with: dateFormatter, parent: nil, using: inflectionType, andRelationshipType: .nested)
    }
    
    
    /**
     Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.
     
     - parameters:
     - dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
     - inflectionType The type used to export the dictionary, can be camelCase or snakeCase.
     - relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
     
     - returns The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary(with dateFormatter: DateFormatter, using inflectionType: SyncPropertyMapperInflectionType, andRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> Dictionary<String, Any?> {
        return hyp_dictionary(with: dateFormatter, parent: nil, using: inflectionType, andRelationshipType: relationshipType)
    }
    
    
    
    /**
     Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.
     
     - parameters:
     - dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the @c hyp_dictionary method.
     - parent           The parent of the managed object.
     - relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
     
     - returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
     */
    func hyp_dictionary(with dateFormatter: DateFormatter, parent: NSManagedObject?, usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> Dictionary<String, Any?> {
        return hyp_dictionary(with: dateFormatter, parent: parent, using: .snakeCase, andRelationshipType: relationshipType)
    }
    
    func hyp_dictionary(with dateFormatter: DateFormatter, parent: NSManagedObject?, using inflectionType: SyncPropertyMapperInflectionType, andRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> Dictionary<String, Any?> {
        
        var managedObjectAttributes: Dictionary<String, Any?> = Dictionary()
        
        for rawPropertyDescription in self.entity.properties {
            if rawPropertyDescription is NSAttributeDescription {
                let propertyDescription = rawPropertyDescription as! NSAttributeDescription
                
                if propertyDescription.shouldExportAttribute() {
                    let value = self.valueForAttributeDescription( propertyDescription, dateFormatter: dateFormatter, relationshipType: relationshipType)
                    if (value != nil) {
                        let remoteKey = self.remoteKeyForAttributeDescription(propertyDescription,
                                                                              usingRelationshipType: relationshipType,
                                                                              inflectionType: inflectionType)

                        let split = remoteKey.components(separatedBy: ".")

                        if split.count == 1 {
                            managedObjectAttributes[split[0]] = value
                            
                        }
                        
                        if split.count == 2 {
                            var level0 = [String : Any?]()
                            if managedObjectAttributes[split[0]] != nil {
                                level0 = managedObjectAttributes[split[0]] as! [String: Any?]
                            }
                            level0[split[1]] = value
                            managedObjectAttributes[split[0]] = level0
                        }
                        
                        if split.count == 3 {
                            var level0 = [String : Any?]()
                            var level1 = [String : Any?]()
                            
                            if managedObjectAttributes[split[0]] != nil {
                                level0 = managedObjectAttributes[split[0]] as! [String : Any?]
                                if level0[split[1]] != nil {
                                    level1 = level0[split[1]] as! [String : Any?]
                                }
                            }
 
                            level1[split[2]] = value
                            level0[split[1]] = level1
                            managedObjectAttributes[split[0]] = level0
                        }
                    }

                }
            } else if ((rawPropertyDescription is NSRelationshipDescription) && (relationshipType != .none)) {
                let relationshipDescription: NSRelationshipDescription = rawPropertyDescription as! NSRelationshipDescription
                if (relationshipDescription.shouldExportAttribute()) {
                    let isValidRelationship = !((parent != nil) && (parent?.entity == relationshipDescription.destinationEntity) && (!relationshipDescription.isToMany))
                    if isValidRelationship {
                        let relationshipName = relationshipDescription.name
                        let relationships: Any? = self.value(forKey: relationshipName)
                        if (relationships != nil) {
                            let isToOneRelationship = (!(relationships is NSSet) && !(relationships is NSOrderedSet))
                            if (isToOneRelationship) {
                                let attributesForToOneRelationship : Dictionary<String, Any> = self.attributesForToOneRelationship(relationships as! NSManagedObject, relationshipName: relationshipName, usingRelationshipType: relationshipType, parent: self, dateFormatter: dateFormatter, inflectionType: inflectionType)
                                managedObjectAttributes.merge(attributesForToOneRelationship) { (_, second) in second }
                            } else {
                                let attributesForToManyRelationship = self.attributesForToManyRelationship(relationships, relationshipName: relationshipName, usingRelationshipType: relationshipType, parent: self, dateFormatter: dateFormatter, inflectionType: inflectionType)
                                managedObjectAttributes.merge(attributesForToManyRelationship) { (_, second) in second }

                            }
                            
                        }
                    }
                }
            }
        }
        return managedObjectAttributes
    }
    
    
    func attributesForToOneRelationship(_ relationship: NSManagedObject, relationshipName: String, usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType, parent: NSManagedObject, dateFormatter: DateFormatter, inflectionType: SyncPropertyMapperInflectionType) -> Dictionary<String, Any>{
        var attributesForToOneRelationship: Dictionary<String, Any> = Dictionary()
        let attributes = relationship.hyp_dictionary(with: dateFormatter, parent: parent, using: inflectionType, andRelationshipType: relationshipType)
        
        
        if (attributes.count > 0) {
            var key: String
            switch inflectionType {
            case .snakeCase:
                key = relationshipName.hyp_snakeCase()
            case .camelCase:
                key = relationshipName
            }
            
            if (relationshipType == .nested) {
                switch inflectionType {
                case .snakeCase:
                    key = key + "_" + PropertyMapperNestedAttributesKey
                case .camelCase:
                    key = key + PropertyMapperNestedAttributesKey.capitalized(with: .none)
                }
            }
            attributesForToOneRelationship.updateValue(attributes, forKey: key)
        }
        return attributesForToOneRelationship
    }

    

    func attributesForToManyRelationship(_ relationships: Any,
                                         relationshipName: String,
                                         usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType,
                                         parent: NSManagedObject,
                                         dateFormatter: DateFormatter,
                                         inflectionType: SyncPropertyMapperInflectionType) -> Dictionary<String, Any> {
        
        var attributesForToManyRelationship: Dictionary<String, Any> = Dictionary()
        var relationIndex = 0
        var relationsDictionary: Dictionary<String, Any> = Dictionary()
        var relationsArray: Array<Dictionary<String, Any>> = Array()
        var relationshipSet: Array<NSManagedObject>
        if (relationships is NSSet) {
            relationshipSet = (relationships as! NSSet).allObjects as! [NSManagedObject]
        } else {
            relationshipSet = (relationships as! NSOrderedSet).array as! [NSManagedObject]
        }

        for relationship in relationshipSet {
            let attributes = relationship.hyp_dictionary(with: dateFormatter, parent: parent, using: inflectionType, andRelationshipType: relationshipType)

            if (attributes.count > 0) {
                if (relationshipType == .array) {
                    relationsArray.append(attributes as [String : Any])
                } else if (relationshipType == .nested) {
                    let relationIndexString: String = "\(relationIndex)"
                    relationsDictionary.updateValue(attributes, forKey: relationIndexString)
                    relationIndex += 1
                }
            }
        }
        
        var key: String
        switch inflectionType {
        case .snakeCase:
            key = relationshipName.hyp_snakeCase()
        case .camelCase:
            key = relationshipName.hyp_camelCase()!
        }
        
        if (relationshipType == .array) {
            attributesForToManyRelationship.updateValue(relationsArray, forKey: key)
        } else if (relationshipType == .nested) {
            let nestedAttributePrefix: String = key + "_" + PropertyMapperNestedAttributesKey
            attributesForToManyRelationship.updateValue(relationsDictionary, forKey: nestedAttributePrefix)
        }
        
        return attributesForToManyRelationship
    }

    
    func defaultDateFormatter() -> DateFormatter  {
        let _dateFormatter = DateFormatter()
        _dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        _dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return _dateFormatter
    }

}


extension Dictionary {
    
    static func += <K, V> (left: inout [K:V], right: [K:V]) {
        for (k, v) in right {
            left[k] = v
        }
    }
}

import Foundation
import CoreData

public extension Sync {
    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DataStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, persistentContainer: NSPersistentContainer, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, persistentContainer: persistentContainer, operations: .all, completion: completion)
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DataStack instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, persistentContainer: NSPersistentContainer, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, persistentContainer: persistentContainer, operations: operations, completion: completion)
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter parent: The parent of the synced items, useful if you are syncing the childs of an object, for example
     an Album has many photos, if this photos don't incldue the album's JSON object, syncing the photos JSON requires
     you to send the parent album to do the proper mapping.
     - parameter dataStack: The DataStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, parent: NSManagedObject, persistentContainer: NSPersistentContainer, completion: ((_ error: NSError?) -> Void)?) {
        persistentContainer.performBackgroundTask { backgroundContext in
            let safeParent = parent.sync_copyInContext(backgroundContext)
            guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: backgroundContext) else { fatalError("Couldn't find entity named: \(entityName)") }
            let relationships = entity.relationships(forDestination: parent.entity)
            var predicate: NSPredicate?
            let firstRelationship = relationships.first

            if let firstRelationship = firstRelationship {
                predicate = NSPredicate(format: "%K = %@", firstRelationship.name, safeParent)
            }
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: safeParent, parentRelationship: firstRelationship?.inverseRelationship, inContext: backgroundContext, operations: .all, completion: completion)
        }
    }
}



extension Sync {
    /// Fetches a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: A managed object for a provided primary key in an specific entity.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func fetch<ResultType: NSManagedObject>(_ id: Any, inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType? {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey!, id as! NSObject)

        let objects = try context.fetch(fetchRequest)

        return objects.first
    }

    /// Inserts or updates an object using the given changes dictionary in an specific entity.
    ///
    /// - Parameters:
    ///   - changes: The dictionary to be used to update or create the object.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: The inserted or updated object. If you call this method from a background context, make sure to not use this on the main thread.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func insertOrUpdate<ResultType: NSManagedObject>(_ changes: [String: Any], inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        guard let id = changes[remotePrimaryKey!] as? NSObject else { fatalError("Couldn't find primary key \(String(describing: remotePrimaryKey)) in JSON for object in entity \(entityName)") }
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey!, id)

        let fetchedObjects = try context.fetch(fetchRequest)
        let insertedOrUpdatedObjects: [ResultType]
        if fetchedObjects.count > 0 {
            insertedOrUpdatedObjects = fetchedObjects
        } else {
            let inserted = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! ResultType
            insertedOrUpdatedObjects = [inserted]
        }

        for object in insertedOrUpdatedObjects {
            object.sync_fill(with: changes, parent: nil, parentRelationship: nil, context: context, operations: [.all], shouldContinueBlock: nil, objectJSONBlock: nil)
        }

        if context.hasChanges {
            try context.save()
        }

        return insertedOrUpdatedObjects.first!
    }

    /// Updates an object using the given changes dictionary for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - changes: The dictionary to be used to update the object.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: The updated object, if not found it returns nil. If you call this method from a background context, make sure to not use this on the main thread.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func update<ResultType: NSManagedObject>(_ id: Any, with changes: [String: Any], inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType? {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { fatalError("Couldn't find an entity named \(entityName)") }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey!, id as! NSObject)

        let objects = try context.fetch(fetchRequest)
        for updated in objects {
            updated.sync_fill(with: changes, parent: nil, parentRelationship: nil, context: context, operations: [.all], shouldContinueBlock: nil, objectJSONBlock: nil)
        }

        if context.hasChanges {
            try context.save()
        }

        return objects.first
    }

    /// Deletes a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Throws: Core Data related issues.
    public class func delete(_ id: Any, inEntityNamed entityName: String, using context: NSManagedObjectContext) throws {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey!, id as! NSObject)

        let objects = try context.fetch(fetchRequest)
        guard objects.count > 0 else { return }

        for deletedObject in objects {
            context.delete(deletedObject)
        }
        
        if context.hasChanges {
            try context.save()
        }
    }
}

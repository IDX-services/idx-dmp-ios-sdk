import CoreData

extension StorageTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: StorageTransformer.self))
    
    public static func register() {
        let transformer = StorageTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}

@objc(StorageTransformer)
class StorageTransformer: NSSecureUnarchiveFromDataTransformer {
    override static var allowedTopLevelClasses: [AnyClass] {
        [Behaviour.self, NSArray.self, NSString.self, NSNumber.self, NSDate.self]
    }
}

final class DBConnector {
    public static let instance: Result<DBConnector, Error> = Result { try DBConnector() }

    private let storeContainer: NSPersistentContainer
    
    private init() throws {
        StorageTransformer.register()
        
        let modelURL = Bundle(for: Storage.self).url(forResource: "IdxDmpSdkStorage", withExtension: "momd")
        let container: NSPersistentContainer

        guard let model = modelURL.flatMap(NSManagedObjectModel.init) else {
            throw EDMPError.databaseConnectFailed
        }

        container = NSPersistentContainer(name: "IdxDmpSdkStorage", managedObjectModel: model)
        container.loadPersistentStores(completionHandler: {(storeDescription, error) in })
        storeContainer = container
    }
    
    private func getBackgroundContext() -> NSManagedObjectContext {
        let context = storeContainer.newBackgroundContext()
        context.mergePolicy = NSOverwriteMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    private func performTaskInCoreData(task: @escaping (NSManagedObjectContext) -> Void) {
        let context = getBackgroundContext()
        context.performAndWait {
            task(context)
        }
    }
    
    public func runTransaction(transaction: @escaping (NSManagedObjectContext) -> Void) {
        performTaskInCoreData { context in
            transaction(context)
        }
    }
}

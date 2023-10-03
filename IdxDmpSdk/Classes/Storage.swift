import CoreData

func getEventComputedId(eventStruct: EventStruct) -> String {
    return "\(eventStruct.defId)_\(eventStruct.behaviourCode)"
}

public class Behaviour: NSObject, NSSecureCoding {
    var uuid: String
    var code: String
    var ordinalNum: Int
    var behaviourType: EBehaviourType?
    var frequencyOperator: EFrequencyOperator?
    var frequencyMin: Int?
    var frequencyMax: Int?
    var frequencyValue: Int?
    var durationUnit: EDateTimeUnit?
    var durationOperator: EDurationOperator?
    var durationMinDate: NSDate?
    var durationMaxDate: NSDate?
    var durationValue: Int?
    
    public static var supportsSecureCoding: Bool = true
    
    public func encode(with coder: NSCoder) {
        coder.encode(uuid, forKey: "uuid")
        coder.encode(code, forKey: "code")
        coder.encode(ordinalNum, forKey: "ordinalNum")
        coder.encode(behaviourType?.rawValue, forKey: "behaviourType")
        coder.encode(frequencyOperator?.rawValue, forKey: "frequencyOperator")
        coder.encode(frequencyMin, forKey: "frequencyMin")
        coder.encode(frequencyMax, forKey: "frequencyMax")
        coder.encode(frequencyValue, forKey: "frequencyValue")
        coder.encode(durationUnit?.rawValue, forKey: "durationUnit")
        coder.encode(durationOperator?.rawValue, forKey: "durationOperator")
        coder.encode(durationMinDate, forKey: "durationMinDate")
        coder.encode(durationMaxDate, forKey: "durationMaxDate")
        coder.encode(durationValue, forKey: "durationValue")
    }
    
    public required convenience init?(coder: NSCoder) {
        let rawBehaviourType = coder.decodeObject(forKey: "behaviourType") as? String
        let rawFrecuencyOperator = coder.decodeObject(forKey: "frequencyOperator") as? String
        let rawDurationUnit = coder.decodeObject(forKey: "durationUnit") as? String
        let rawDurationOperator = coder.decodeObject(forKey: "durationOperator") as? String

        self.init(behaviourStruct: BehaviourStruct(
            uuid: coder.decodeObject(forKey: "uuid") as! String,
            code: coder.decodeObject(forKey: "code") as! String,
            ordinalNum: coder.decodeInteger(forKey: "ordinalNum"),
            behaviourType: (rawBehaviourType != nil) ? EBehaviourType(rawValue: rawBehaviourType!) : nil,
            frequencyOperator: (rawFrecuencyOperator != nil) ? EFrequencyOperator(rawValue: rawFrecuencyOperator!) : nil,
            frequencyMin: coder.decodeObject(forKey: "frequencyMin") as? Int,
            frequencyMax: coder.decodeObject(forKey: "frequencyMax") as? Int,
            frequencyValue: coder.decodeObject(forKey: "frequencyValue") as? Int,
            durationUnit: (rawDurationUnit != nil) ? EDateTimeUnit(rawValue: rawDurationUnit!) : nil,
            durationOperator: (rawDurationOperator != nil) ? EDurationOperator(rawValue: rawDurationOperator!) : nil,
            durationMinDate: coder.decodeObject(forKey: "durationMinDate") as? Date,
            durationMaxDate: coder.decodeObject(forKey: "durationMaxDate") as? Date,
            durationValue: coder.decodeObject(forKey: "durationValue") as? Int
        ))
    }
    
    init(behaviourStruct: BehaviourStruct) {
        self.uuid = behaviourStruct.uuid
        self.code = behaviourStruct.code
        self.ordinalNum = behaviourStruct.ordinalNum
        self.behaviourType = behaviourStruct.behaviourType
        self.frequencyOperator = behaviourStruct.frequencyOperator
        self.frequencyMin = behaviourStruct.frequencyMin
        self.frequencyMax = behaviourStruct.frequencyMax
        self.frequencyValue = behaviourStruct.frequencyValue
        self.durationUnit = behaviourStruct.durationUnit
        self.durationOperator = behaviourStruct.durationOperator
        self.durationMinDate = behaviourStruct.durationMinDate as? NSDate
        self.durationMaxDate = behaviourStruct.durationMaxDate as? NSDate
        self.durationValue = behaviourStruct.durationValue
    }
}

extension Definition {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Definition> {
        return NSFetchRequest<Definition>(entityName: "Definition")
    }

    @NSManaged public var behaviours: [Behaviour]
    @NSManaged public var code: String
    @NSManaged public var defId: String
    @NSManaged public var lastModifiedDate: String
    @NSManaged public var debugEnabled: Bool
    @NSManaged public var revision: Int16
    @NSManaged public var uuid: UUID
    
    @NSManaged private var typeRaw: String
    @NSManaged private var statusRaw: String
    @NSManaged private var behaviourOperatorsRaw: NSArray
    
    public var type: EDefinitionType {
        get {
            return EDefinitionType(rawValue: self.typeRaw) ?? .STANDARD
        }
        set {
            self.typeRaw = String(newValue.rawValue)
        }
    }
    
    public var status: EDefinitionStatus {
        get {
            return EDefinitionStatus(rawValue: self.statusRaw) ?? .INDEXING
        }
        set {
            self.statusRaw = String(newValue.rawValue)
        }
    }
    
    public var behaviourOperators: [EBehaviourOperator] {
        get {
            return behaviourOperatorsRaw.map {val in
                EBehaviourOperator(rawValue: val as! String)!
            }
        }
        set {
            self.behaviourOperatorsRaw = newValue.map {val in
                val.rawValue
            } as NSArray
        }
    }
    
    public func setData(definitionStruct: DefinitionStruct) {
        defId = definitionStruct.defId
        revision = Int16(definitionStruct.revision)
        type = definitionStruct.type ?? .STANDARD
        status = definitionStruct.status
        code = definitionStruct.code
        uuid = UUID(uuidString: definitionStruct.uuid)!
        lastModifiedDate = definitionStruct.lastModifiedDate
        debugEnabled = definitionStruct.debugEnabled ?? false

        behaviours = definitionStruct.behaviours.map {behaviour in
            Behaviour(behaviourStruct: behaviour)
        }
        behaviourOperators = definitionStruct.behaviourOperators
    }
}

@objc(Definition)
class Definition: NSManagedObject {

}

extension Event {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var computedId: String
    @NSManaged public var defId: String
    @NSManaged public var behaviourCode: String
    @NSManaged public var timestamps: NSArray
    
    public func setData(eventStruct: EventStruct) {
        computedId = getEventComputedId(eventStruct: eventStruct)
        defId = eventStruct.defId
        behaviourCode = eventStruct.behaviourCode
        timestamps = eventStruct.timestamps as NSArray
    }
}

@objc(Event)
class Event: NSManagedObject {

}

@available(iOS 12.0, *)
extension StorageTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: StorageTransformer.self))
    
    public static func register() {
        let transformer = StorageTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}

@available(iOS 12.0, *)
@objc(StorageTransformer)
class StorageTransformer: NSSecureUnarchiveFromDataTransformer {
    override static var allowedTopLevelClasses: [AnyClass] {
        [Behaviour.self, NSArray.self, NSString.self, NSNumber.self, NSDate.self]
    }
}

final class Storage {
    private var storeContainer: NSPersistentContainer
    private var managedContext: NSManagedObjectContext

    public init() throws {
        do {
            if #available(iOS 12.0, *) {
                StorageTransformer.register()
            } else {
                throw EDMPError.databaseConnectFailed
            }
            
            let modelURL = Bundle(for: Storage.self).url(forResource: "IdxDmpSdkStorage", withExtension: "momd")
            var container: NSPersistentContainer

            guard let model = modelURL.flatMap(NSManagedObjectModel.init) else {
                throw EDMPError.databaseConnectFailed
            }

            container = NSPersistentContainer(name: "IdxDmpSdkStorage", managedObjectModel: model)
            container.loadPersistentStores(completionHandler: {(storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            container.viewContext.mergePolicy = NSOverwriteMergePolicy

            storeContainer = container
            managedContext = container.viewContext
        } catch {
            throw EDMPError.databaseConnectFailed
        }
    }
    
    public func setDefinitions(definitions: [DefinitionStruct]) throws {
        do {
            definitions.forEach { definitionStruct in
                let definition = Definition(context: managedContext)
                definition.setData(definitionStruct: definitionStruct)
            }

            try managedContext.save()
        } catch {
            throw EDMPError.setDefinitionsFailed
        }
    }
    
    public func getDefinitions() -> [Definition] {
        do {
            return try managedContext.fetch(Definition.fetchRequest())
        } catch {
            return []
        }
    }
    
    public func removeDefinitions(_ definitionIds: [String]) throws {
        do {
            if (definitionIds.isEmpty) {
                return
            }
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Definition")
            request.predicate = NSPredicate(
                format: "defId IN %@", definitionIds
            )
            
            try managedContext.execute(NSBatchDeleteRequest(fetchRequest: request))
        } catch {
            throw EDMPError.removePartialEvents
        }
    }
    
    public func removeAllDefinitions() throws {
        do {
            try managedContext.execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Definition")))
        } catch {
            throw EDMPError.removeAllDefinitions
        }
    }
    
    public func setEvents(events: [EventStruct]) throws {
        do {
            events.forEach { eventStruct in
                let event = Event(context: managedContext)
                event.setData(eventStruct: eventStruct)
            }
            
            try managedContext.save()
        } catch {
            throw EDMPError.setEventsFailed
        }
    }
    
    public func getEvents() -> [Event] {
        do {
            return try managedContext.fetch(Event.fetchRequest())
        } catch {
            return []
        }
    }
    
    public func removeEventsByDefinitions(_ definitionIds: [String]) throws {
        do {
            if (definitionIds.isEmpty) {
                return
            }
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
            request.predicate = NSPredicate(
                format: "defId IN %@", definitionIds
            )
            
            try managedContext.execute(NSBatchDeleteRequest(fetchRequest: request))
        } catch {
            throw EDMPError.removePartialEvents
        }
    }
    
    public func removeOneTimeEvents() throws {
        do {
            let oneTimeDefinitionIds = self.getDefinitions()
                .filter({ $0.type == EDefinitionType.CURRENT_PAGE })
                .map({ return $0.defId })
            
            try self.removeEventsByDefinitions(oneTimeDefinitionIds)
        } catch {
            throw EDMPError.removeOneTimeEvents
        }
    }
    
    public func removeAllEvents() throws {
        do {
            try managedContext.execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Event")))
        } catch {
            throw EDMPError.removeAllEvents
        }
    }
    
    public func mergeEvents(newEvents: [EventStruct]) throws {
        let oldEvents = self.getEvents()

        do {
            newEvents.forEach { eventStruct in
                if let currentOldEvent: Event = oldEvents.first(
                    where: {$0.computedId == getEventComputedId(eventStruct: eventStruct)}
                ) {
                    currentOldEvent.timestamps = currentOldEvent.timestamps
                        .addingObjects(from: eventStruct.timestamps)
                        .sorted {a, b in (a as! Int) > (b as! Int)} as NSArray
                    let removeCount = currentOldEvent.timestamps.count - Config.Constant.maxEventCount
                    if (removeCount > 0) {
                        currentOldEvent.timestamps = currentOldEvent.timestamps.dropLast(removeCount) as NSArray
                    }
                } else {
                    let event = Event(context: managedContext)
                    event.setData(eventStruct: eventStruct)
                }
            }

            try managedContext.save()
        } catch {
            throw EDMPError.mergeEventsFailed
        }
    }
    
    public func removeStorageData() throws {
        do {
            try self.removeAllEvents()
            try self.removeAllDefinitions()
        } catch {
            throw EDMPError.removeAllStorage
        }
    }
}

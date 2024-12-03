import CoreData

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

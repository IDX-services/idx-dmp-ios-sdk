import RealmSwift

func getEventComputedId(eventStruct: EventStruct) -> String {
    return "\(eventStruct.defId)_\(eventStruct.behaviourCode)"
}

class Behaviour: EmbeddedObject {
    @Persisted var uuid: String
    @Persisted var code: String
    @Persisted var ordinalNum: Int
    @Persisted var frequencyOperator: EFrequencyOperator?
    @Persisted var frequencyMin: Int?
    @Persisted var frequencyMax: Int?
    @Persisted var frequencyValue: Int?
    @Persisted var durationUnit: EDateTimeUnit?
    @Persisted var durationOperator: EDurationOperator?
    @Persisted var durationMinDate: Date?
    @Persisted var durationMaxDate: Date?
    @Persisted var durationValue: Int?
    
    convenience init(behaviourStruct: BehaviourStruct) {
        self.init()
        self.uuid = behaviourStruct.uuid
        self.code = behaviourStruct.code
        self.frequencyOperator = behaviourStruct.frequencyOperator
        self.frequencyMin = behaviourStruct.frequencyMin
        self.frequencyMax = behaviourStruct.frequencyMax
        self.frequencyValue = behaviourStruct.frequencyValue
        self.durationUnit = behaviourStruct.durationUnit
        self.durationOperator = behaviourStruct.durationOperator
        self.durationMinDate = behaviourStruct.durationMinDate
        self.durationMaxDate = behaviourStruct.durationMaxDate
        self.durationValue = behaviourStruct.durationValue
    }
}

class Definition: Object {
    @Persisted(primaryKey: true) var defId: String
    @Persisted var uuid: String
    @Persisted var code: String
    @Persisted var revision: Int
    @Persisted var status: EDefinitionStatus
    @Persisted var behaviours: List<Behaviour> = List<Behaviour>()
    @Persisted var behaviourOperators: List<EBehaviourType> = List<EBehaviourType>()
    @Persisted var lastModifiedDate: String

    convenience init(definitionStruct: DefinitionStruct) {
        self.init()
        self.defId = definitionStruct.defId
        self.uuid = definitionStruct.uuid
        self.code = definitionStruct.code
        self.status = definitionStruct.status
        definitionStruct.behaviours.forEach { behaviour in
            self.behaviours.append(Behaviour(behaviourStruct: behaviour))
        }
        definitionStruct.behaviourOperators.forEach { behaviourOperator in
            self.behaviourOperators.append(behaviourOperator)
        }
        self.lastModifiedDate = definitionStruct.lastModifiedDate
    }
}

class Event: Object {
    @Persisted(primaryKey: true) var computedId: String
    @Persisted var defId: String
    @Persisted var behaviourCode: String
    @Persisted var timestamps: List<Int>
    
    convenience init(eventStruct: EventStruct) {
        self.init()
        self.computedId = getEventComputedId(eventStruct: eventStruct)
        self.defId = eventStruct.defId
        self.behaviourCode = eventStruct.behaviourCode
        eventStruct.timestamps.forEach { timestamp in
            self.timestamps.append(timestamp)
        }
    }
}

final class Storage {
    private var database: Realm!
    
    public init() {
        do {
            database = try Realm()
        } catch {
            print("Open realm connect has failed")
        }
    }
    
    public func setDefinitions(definitions: [DefinitionStruct]) {
        do {
            try self.database.write() {
                definitions.forEach { definition in
                    let def = Definition(definitionStruct: definition)
                    self.database.add(def, update: .all)
                }
            }
        } catch {
            print("setDefinitions has failed")
        }
    }
    
    public func getDefinitions() -> Results<Definition> {
        return self.database.objects(Definition.self)
    }
    
    public func setEvents(events: [EventStruct]) {
        do {
            try self.database.write() {
                events.forEach { event in
                    let event = Event(eventStruct: event)
                    self.database.add(event, update: .all)
                }
            }
        } catch {
            print("setEvents has failed")
        }
    }
    
    public func getEvents() -> Results<Event> {
        return self.database.objects(Event.self)
    }
    
    public func mergeEvents(newEvents: [EventStruct]) {
        let oldEvents = self.getEvents()
        
        do {
            try self.database.write() {
                newEvents.forEach { eventStruct in
                    let currentOldEvent: Event! = oldEvents.first(where: {$0.computedId == getEventComputedId(eventStruct: eventStruct)})

                    if (currentOldEvent != nil) {
                        eventStruct.timestamps.forEach {t in
                            currentOldEvent.timestamps.append(t)
                        }
                        currentOldEvent.timestamps.sort { a, b in
                            return b > a
                        }
                        let removeCount = currentOldEvent.timestamps.count - 50
                        if (removeCount > 0) {
                            currentOldEvent.timestamps.removeFirst(removeCount)
                        }
                    } else {
                        let event = Event(eventStruct: eventStruct)
                        self.database.add(event, update: .all)
                    }
                }
            }
        } catch {
            print("mergeEvents has failed")
        }
    }
}

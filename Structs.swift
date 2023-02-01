struct BehaviourStruct: Decodable {
    let uuid: String
    let code: String
    let ordinalNum: Int
    let frequencyOperator: EFrequencyOperator?
    let frequencyMin: Int?
    let frequencyMax: Int?
    let frequencyValue: Int?
    let durationUnit: EDateTimeUnit?
    let durationOperator: EDurationOperator?
    let durationMinDate: Date?
    let durationMaxDate: Date?
    let durationValue: Int?
}

struct DefinitionStruct: Decodable {
    let defId: String
    let uuid: String
    let code: String
    let revision: Int
    let status: EDefinitionStatus
    let behaviours: [BehaviourStruct]
    let behaviourOperators: [EBehaviourType]
    let lastModifiedDate: String
}

struct EventStruct: Decodable {
    let defId: String
    let behaviourCode: String
    let timestamps: [Int]
}

struct UserStateStruct: Decodable {
    let userId: String
    let lastModifiedTimestamp: Int
    let action: EDatabaseAction
    let definitions: [DefinitionStruct]
    let deletedDefinitionIds: [String]
    let events: [EventStruct]
}

public struct EventRequestPropertiesStruct: Encodable {
    let url: String
    let title: String
    let domain: String
    let author: String
    let category: String
    let description: String
    let tags: [String]

    public init(
        url: String,
        title: String,
        domain: String,
        author: String,
        category: String,
        description: String,
        tags: [String]
    ) {
        self.url = url
        self.title = title
        self.domain = domain
        self.author = author
        self.category = category
        self.description = description
        self.tags = tags
    }
}

public struct EventRequestStruct: Encodable {
    let event: EDMPEvent
    let userId: String
    let providerId: String
    let properties: EventRequestPropertiesStruct
}

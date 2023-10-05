struct BehaviourStruct: Decodable {
    let uuid: String
    let code: String
    let ordinalNum: Int
    let behaviourType: EBehaviourType?
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
    let type: EDefinitionType?
    let status: EDefinitionStatus
    let behaviours: [BehaviourStruct]
    let behaviourOperators: [EBehaviourOperator]
    let lastModifiedDate: String
    let debugEnabled: Bool?
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
    public let url: String
    public let title: String
    public let domain: String
    public let author: String
    public let category: String
    public let description: String
    public let tags: [String]
    public let devicePlatform: String

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
        self.devicePlatform = "MOBILE_APP"
    }
}

public struct EventRequestStruct: Encodable {
    let event: EDMPEvent
    let userId: String
    let providerId: String
    let properties: EventRequestPropertiesStruct
}

struct EventQueueItem {
    let properties: EventRequestPropertiesStruct
    let callback: (Any?) -> Void
}

struct EnterAndExitDefinitionIds {
    let enterIds: [String]
    let exitIds: [String]
}

struct StatisticEventRequestStruct: Encodable {
    let event: EDMPStatisticEvent
    let userId: String
    let providerId: String
    let audienceCode: String
    let actualAudienceCodes: [String]
}

struct MonitoringRequestStruct: Encodable {
    let loggerLog: [String]
}

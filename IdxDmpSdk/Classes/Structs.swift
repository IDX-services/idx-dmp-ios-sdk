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

public struct SdkMetaDataStruct: Encodable {
    public let sdkName: String
    public let sdkVer: String
    public let appName: String
    public let appVer: String

    public init(
        sdkName: String,
        sdkVer: String,
        appName: String,
        appVer: String
    ) {
        self.sdkName = sdkName
        self.sdkVer = sdkVer
        self.appName = appName
        self.appVer = appVer
    }
}

public struct EventRequestStruct: Encodable {
    let event: EDMPEvent
    let userId: String
    let providerId: String
    let dxf: String
    let properties: EventRequestPropertiesStruct
    let srcMeta: SdkMetaDataStruct
}

struct EventQueueItem {
    let properties: EventRequestPropertiesStruct
    let callback: (Any?) -> Void
}

struct EnterAndExitDefinitionIds {
    let enterIds: [String]
    let exitIds: [String]
}

public struct EventRequestAdditionalPropertiesStruct: Encodable {
    public let devicePlatform: String

    public init() {
        self.devicePlatform = "MOBILE_APP"
    }
}

struct StatisticEventRequestStruct: Encodable {
    let event: EDMPStatisticEvent
    let userId: String
    let providerId: String
    let audienceCode: String
    let actualAudienceCodes: [String]
    let properties: EventRequestAdditionalPropertiesStruct
    let srcMeta: SdkMetaDataStruct
    
    public init(
        event: EDMPStatisticEvent,
        userId: String,
        providerId: String,
        audienceCode: String,
        actualAudienceCodes: [String],
        srcMeta: SdkMetaDataStruct
    ) {
        self.event = event
        self.userId = userId
        self.providerId = providerId
        self.audienceCode = audienceCode
        self.actualAudienceCodes = actualAudienceCodes
        self.properties = EventRequestAdditionalPropertiesStruct()
        self.srcMeta = srcMeta
    }
}

struct SyncEventRequestStruct: Encodable {
    let event: EDMPSyncEvent
    let userId: String
    let providerId: String
    let actualAudienceCodes: [String]
    let properties: EventRequestAdditionalPropertiesStruct
    let srcMeta: SdkMetaDataStruct
    
    public init(
        event: EDMPSyncEvent,
        userId: String,
        providerId: String,
        actualAudienceCodes: [String],
        srcMeta: SdkMetaDataStruct
    ) {
        self.event = event
        self.userId = userId
        self.providerId = providerId
        self.actualAudienceCodes = actualAudienceCodes
        self.properties = EventRequestAdditionalPropertiesStruct()
        self.srcMeta = srcMeta
    }
}

struct MonitoringRequestStruct: Encodable {
    let loggerLog: [String]
}

struct DataCollectionConfigItemFieldStruct: Decodable {
    let type: EDataCollectionConfigItemFieldType
    let path: String
    let uuid: String?
    let name: String?
}

struct FieldExtractionConfigStruct: Decodable {
    let uuid: String
    let type: EFieldExtractionConfigType
    let field: DataCollectionConfigItemFieldStruct
    let expression: String
}

struct MonitoringConfigStruct: Decodable {
    let uuid: String
    let enabled: Bool
    let verboseMode: EMonitoringVerboseMode
    let includeDatabase: Bool
    let includeLoggerState: Bool
    let includeLocalStorage: Bool
    let sampling: Int?
    let observedUserId: String?
}

struct ProviderExclusionStruct: Decodable {
    let uuid: String
    let expression: String
    let type: EProviderExclusionType
}

struct ProviderActivationStruct: Decodable {
    let uuid: String?
    let sdkWebEnabled: Bool?
    let sdkIosEnabled: Bool?
    let sdkAndroidEnabled: Bool?
    let sdkFlutterEnabled: Bool?
    let sdkReactNativeEnabled: Bool?
}

struct ProviderConfigStruct: Decodable {
    let uuid: String
    let fieldExtractions: [FieldExtractionConfigStruct]
    let providerExclusions: [ProviderExclusionStruct]
    let isDataCollectionEnabled: Bool
    let isDFPActivationEnabled: Bool
    let pingFrequencySec: Int
    let providerMonitoring: MonitoringConfigStruct
    let providerSdk: ProviderActivationStruct?
}

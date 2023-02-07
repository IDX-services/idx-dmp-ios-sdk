import RealmSwift

enum EDMPEvent: String, Encodable {
    case PAGE_VIEW
}

enum EDefinitionStatus: String, Decodable, PersistableEnum {
    case INDEXING, ACTIVATED
}

enum EFrequencyOperator: String, Decodable, PersistableEnum {
    case EXACTLY,
    BETWEEN,
    AT_MOST,
    AT_LEAST,
    NOT_DEFINED
}

enum EDateTimeUnit: String, Decodable, PersistableEnum {
    case HOURS,
    DAYS,
    WEEKS,
    MONTHS
}

enum EDurationOperator: String, Decodable, PersistableEnum {
    case ALL,
    LAST,
    AFTER,
    BEFORE,
    BETWEEN,
    CURRENT_PAGE
}

enum EBehaviourType: String, Decodable, PersistableEnum {
    case OR, AND
}

enum EDatabaseAction: String, Decodable {
    case UPDATE, REPLACE
}

enum EDMPError: Error {
    case cannotCreateUrl(from: String)
    case urlIsNil
    case responseIsEmpty
    case setEventsFailed
    case mergeEventsFailed
    case setDefinitionsFailed
    case databaseConnectFailed
    case userIdIsEmpty
    case userDataIsEmpty
    case userDataParseError
}

enum EDMPEvent: String, Encodable {
    case PAGE_VIEW
}

enum EDefinitionType: String, Decodable {
    case STANDART, CURRENT_PAGE
}

enum EDefinitionStatus: String, Decodable {
    case INDEXING, ACTIVATED
}

enum EFrequencyOperator: String, Decodable {
    case EXACTLY,
    BETWEEN,
    AT_MOST,
    AT_LEAST,
    NOT_DEFINED
}

enum EDateTimeUnit: String, Decodable {
    case HOURS,
    DAYS,
    WEEKS,
    MONTHS
}

enum EDurationOperator: String, Decodable {
    case ALL,
    LAST,
    AFTER,
    BEFORE,
    BETWEEN
}

enum EBehaviourType: String, Decodable {
    case CURRENT_PAGE
}

enum EBehaviourOperator: String, Decodable {
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
    case removeAllEvents
    case removeAllDefinitions
    case removeAllStorage
    case removeOneTimeEvents
    case removePartialEvents
    case databaseConnectFailed
    case userIdIsEmpty
    case userDataIsEmpty
    case userDataParseError
    case requestError
}

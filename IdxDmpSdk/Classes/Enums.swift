enum EDMPEvent: String, Encodable {
    case PAGE_VIEW
}

enum EDMPStatisticEvent: String, Encodable {
    case AUDIENCE_ENTER, AUDIENCE_EXIT
}

enum EDMPSyncEvent: String, Encodable {
    case AUDIENCE_PING
}

enum EDefinitionType: String, Decodable {
    case STANDARD, CURRENT_PAGE
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
    case MAIN, CURRENT_PAGE
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
    case configDataIsEmpty
    case configDataParseError
    case configExpressionError
    case webViewDataAlwaysEmpty
    case requestError
}

enum EDataCollectionConfigItemFieldType: String, Decodable {
    case STRING, DOUBLE, LONG, ARRAY_OF_STRING
}

enum EFieldExtractionConfigType: String, Decodable {
    case URL_REGEX, GLOBAL_VARIABLE, META_NAME, META_PROPERTY, JAVASCRIPT
}

enum EMonitoringVerboseMode: String, Decodable {
    case ALL, WARNINGS, ERRORS
}

enum EProviderExclusionType: String, Decodable {
    case URL_CONTAINS, URL_EXACTLY_MATCH, CATEGORY_EQUALS
}

struct Config {
    struct Api {
        static let baseUrl = "https://dev-event.dxmdp.com/rest/api/v1"
        static let stateUrl = "\(Config.Api.baseUrl)/state"
        static let eventUrl = "\(Config.Api.baseUrl)/events"
    }
    struct Date {
        static let format = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    }
}

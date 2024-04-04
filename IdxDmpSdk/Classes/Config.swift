struct Config {
    struct Api {
        private static let baseUrl = "https://event.dxmdp.com/rest/api/v1"
        private static let backofficeUrl = "https://tags.dxmdp.com"

        static let stateUrl = "\(Config.Api.baseUrl)/state"
        static let eventUrl = "\(Config.Api.baseUrl)/events"
        static let monitoringUrl = "\(Config.Api.baseUrl)/report-error"
        static let configUrl = "\(Config.Api.backofficeUrl)/tags/:providerId/config"

        static let cookieIsEnabled = false
    }
    struct Date {
        static let format = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    }
    struct Constant {
        static let maxEventCount = 50
    }
}

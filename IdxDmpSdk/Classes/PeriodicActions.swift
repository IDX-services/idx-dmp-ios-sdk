extension Date {
    func getCurrentTimestamp() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

final class PeriodicActions {
    static let localStorage = UserDefaults.standard
    
    private static func getLocalStorageKey(_ actionName: String) -> String {
        return "palt-\(actionName)"
    }

    private static func getPeriodicActionLastTimestamp(_ actionName: String) -> Int64 {
        let lastTimestamp = localStorage.integer(forKey: getLocalStorageKey(actionName))

        return Int64(lastTimestamp)
    }

    static func runAction(intervalMs: Int64, actionName: String, action: () -> Void, errorHandler: ((Error?) -> Void)? = { _ in }) {
        let currentTimestamp = Date().getCurrentTimestamp()
        
        if (currentTimestamp >= getPeriodicActionLastTimestamp(actionName) + intervalMs) {
            action()
            localStorage.set(currentTimestamp, forKey: getLocalStorageKey(actionName))
        }
    }
}

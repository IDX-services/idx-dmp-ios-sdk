enum ELogLevel: Int {
    case None = 0,
    Errors,
    Warnings,
    All
}

final class Monitoring {
    private let logLevel: ELogLevel
    private var logHistory: [String] = []

    init (_ logLevel: ELogLevel = ELogLevel.None) {
        self.logLevel = logLevel
    }
    
    private func printMessage(_ message: String) {
        logHistory.append(message)

        NSLog("[DMP Log]: \(message)")
    }

    func log(_ message: String) {
        if (self.logLevel.rawValue < ELogLevel.All.rawValue) {
            return
        }
        
        self.printMessage(message)
    }
    
    func warning(_ message: String) {
        if (self.logLevel.rawValue < ELogLevel.Warnings.rawValue) {
            return
        }
        
        self.printMessage(message)
    }
    
    func error(_ errorInstance: any Error) {
        if (self.logLevel.rawValue < ELogLevel.Errors.rawValue) {
            return
        }
        
        switch errorInstance {
        case EDMPError.cannotCreateUrl(let from):
            self.printMessage("Cannot create url form \(from)")
        case EDMPError.urlIsNil:
            self.printMessage("Url is nil")
        case EDMPError.responseIsEmpty:
            self.printMessage("Api response is empty")
        case EDMPError.setEventsFailed:
            self.printMessage("Set events failed")
        case EDMPError.mergeEventsFailed:
            self.printMessage("Merge events failed")
        case EDMPError.setDefinitionsFailed:
            self.printMessage("Set definitions failed")
        case EDMPError.removeAllEvents:
            self.printMessage("Remove all events failed")
        case EDMPError.removeAllDefinitions:
            self.printMessage("Remove all definitions failed")
        case EDMPError.removeAllStorage:
            self.printMessage("Remove all storage failed")
        case EDMPError.databaseConnectFailed:
            self.printMessage("Database is not available")
        case EDMPError.userIdIsEmpty:
            self.printMessage("User id is empty")
        case EDMPError.userDataIsEmpty:
            self.printMessage("User data is empty")
        case EDMPError.userDataParseError:
            self.printMessage("User data parse error")
        case EDMPError.configDataIsEmpty:
            self.printMessage("Config data is empty")
        case EDMPError.configDataParseError:
            self.printMessage("Config data parse error")
        case EDMPError.configExpressionError:
            self.printMessage("Config expression error")
        default:
            self.printMessage("Unknown exception, error: \(errorInstance)")
        }
    }
    
    func complete(_ withError: (any Error)? = nil) {
        if let error = withError {
            self.error(error)
        }

        if (self.logHistory.count < 1) {
            return
        }

        let requestBody = MonitoringRequestStruct(
            loggerLog: self.logHistory
        )
        
        do {
            try Api.post(
                url: Config.Api.monitoringUrl,
                body: requestBody
            )
            self.logHistory = []
        } catch {
            self.error(error)
        }
    }
}

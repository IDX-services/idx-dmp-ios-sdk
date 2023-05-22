enum ELogLevel: Int {
    case None = 0,
    Errors,
    All
}

final class Logger {
    private let logLevel: ELogLevel

    init (logLevel: ELogLevel = ELogLevel.All) {
        self.logLevel = logLevel
    }
    
    private func printMessage(_ message: String) {
        debugPrint("[DMP Log]: \(message)")
    }

    func log(_ message: String) {
        if (self.logLevel.rawValue < ELogLevel.All.rawValue) {
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
        default:
            self.printMessage("Unknown exception, error: \(errorInstance)")
        }
    }
}

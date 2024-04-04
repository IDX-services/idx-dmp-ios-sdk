private enum ELogLevel: Int {
    case None = 0,
    All,
    Warnings,
    Errors
}

final class Monitoring {
    private var currentLogLevel: ELogLevel = .None
    private var monitoringConfig: MonitoringConfigStruct?
    private var logHistory: [String] = []
    private var userId: String?
    private var label: String?
    private var buildNumber: String = Bundle(identifier: "org.cocoapods.IdxDmpSdk")?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    
    init (label: String?) {
        self.label = label
    }
    
    private func getLogLevelByVerboseMode() -> ELogLevel {
        switch monitoringConfig?.verboseMode {
        case .ALL:
            return .All
        case .WARNINGS:
            return .Warnings
        case.ERRORS:
            return .Errors
        default:
            return .None
        }
    }
    
    private func setCurrentLevel (_ level: ELogLevel) {
        if (currentLogLevel.rawValue < level.rawValue) {
            currentLogLevel = level
        }
    }
    
    private func printMessage(_ message: String, _ level: ELogLevel) {
        setCurrentLevel(level)
        let formattedMessage = "[DMP monitoring, platform: iOS, version: \(buildNumber)" + (label != nil ? ", label: \(label!)" : "") + "]: \(message)"

        logHistory.append(formattedMessage)
        NSLog(formattedMessage)
    }
    
    func setMonitoringConfig (_ monitoringConfig: MonitoringConfigStruct) {
        self.monitoringConfig = monitoringConfig
    }
    
    func setUserId (_ userId: String) {
        self.userId = userId
    }

    func log(_ message: String) {
        self.printMessage(message, ELogLevel.All)
    }
    
    func warning(_ message: String) {
        self.printMessage(message, ELogLevel.Warnings)
    }
    
    func error(_ errorInstance: any Error) {
        switch errorInstance {
        case EDMPError.cannotCreateUrl(let from):
            self.printMessage("Cannot create url form \(from)", ELogLevel.Errors)
        case EDMPError.urlIsNil:
            self.printMessage("Url is nil", ELogLevel.Errors)
        case EDMPError.responseIsEmpty:
            self.printMessage("Api response is empty", ELogLevel.Errors)
        case EDMPError.setEventsFailed:
            self.printMessage("Set events failed", ELogLevel.Errors)
        case EDMPError.mergeEventsFailed:
            self.printMessage("Merge events failed", ELogLevel.Errors)
        case EDMPError.setDefinitionsFailed:
            self.printMessage("Set definitions failed", ELogLevel.Errors)
        case EDMPError.removeAllEvents:
            self.printMessage("Remove all events failed", ELogLevel.Errors)
        case EDMPError.removeAllDefinitions:
            self.printMessage("Remove all definitions failed", ELogLevel.Errors)
        case EDMPError.removeAllStorage:
            self.printMessage("Remove all storage failed", ELogLevel.Errors)
        case EDMPError.databaseConnectFailed:
            self.printMessage("Database is not available", ELogLevel.Errors)
        case EDMPError.userIdIsEmpty:
            self.printMessage("User id is empty", ELogLevel.Errors)
        case EDMPError.userDataIsEmpty:
            self.printMessage("User data is empty", ELogLevel.Errors)
        case EDMPError.userDataParseError:
            self.printMessage("User data parse error", ELogLevel.Errors)
        case EDMPError.configDataIsEmpty:
            self.printMessage("Config data is empty", ELogLevel.Errors)
        case EDMPError.configDataParseError:
            self.printMessage("Config data parse error", ELogLevel.Errors)
        case EDMPError.configExpressionError:
            self.printMessage("Config expression error", ELogLevel.Errors)
        case EDMPError.webViewDataAlwaysEmpty:
            self.printMessage("[DMPWebViewConnector error] Web view data always empty!", ELogLevel.Errors)
        default:
            self.printMessage("Unknown exception, error: \(errorInstance)", ELogLevel.Errors)
        }
    }
    
    func complete(_ withError: (any Error)? = nil) {
        if let error = withError {
            self.error(error)
        }
        
        guard let monitoringConfig = self.monitoringConfig else {
            return
        }
        
        if (!monitoringConfig.enabled) {
            return
        }
        
        if (
            monitoringConfig.observedUserId != nil &&
            !monitoringConfig.observedUserId!.isEmpty &&
            monitoringConfig.observedUserId != userId
        ) {
            return
        }
        
        if (getLogLevelByVerboseMode().rawValue > currentLogLevel.rawValue) {
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

import AdSupport
import AppTrackingTransparency

public final class DataManagerProvider {
    let providerId: String
    let localStorage = UserDefaults.standard
    let monitoring: Monitoring
    let databaseStorage: Storage?
    let sdkMetaData: SdkMetaDataStruct
    
    let asyncEventsQueue = AsyncEventQueue()

    var providerConfig: ProviderConfigStruct?
    var definitionIds: [String] = []
    var advertisingId: String = ""
    
    public init(providerId: String, appName: String, appVersion: String, completionHandler: @escaping (Any?) -> Void = {_ in}) {
        self.providerId = providerId
        self.monitoring = Monitoring(label: appName)
        self.sdkMetaData = SdkMetaDataStruct(
            sdkName: "iOS DMP CORE SDK",
            sdkVer: monitoring.getBuildNumber(),
            appName: appName,
            appVer: appVersion
        )
        
        self.monitoring.log("Init with provider id: \(providerId)")
        do {
            if #available(iOS 12.0, *) {
                databaseStorage = try Storage(monitoring: self.monitoring)
            } else {
                throw EDMPError.databaseConnectFailed
            }

            if #available(iOS 14.0, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    if (status == .authorized) {
                        self.advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    }
                }
            }

            self.getConfig(completionHandler: completionHandler)
            self.getState(completionHandler: completionHandler)
        } catch {
            databaseStorage = nil
            self.monitoring.complete(EDMPError.databaseConnectFailed)
        }
    }
    
    private func setUserId(userId: String) {
        localStorage.set(userId, forKey: "userId")
        monitoring.setUserId(userId)
    }
    
    public func getUserId() -> String? {
        return localStorage.string(forKey: "userId")
    }
    
    private func setTimestamp(ts: String) {
        localStorage.set(ts, forKey: "ts")
    }
    
    public func getTimestamp() -> String? {
        return localStorage.string(forKey: "ts")
    }
    
    private func setPrevDefinitionIds(_ definitionIds: [String]) {
        localStorage.set(definitionIds, forKey: "prevDefinitionids")
    }
    
    private func getPrevDefinitionIds() -> [String] {
        return localStorage.stringArray(forKey: "prevDefinitionids") ?? []
    }
    
    public func getProviderId() -> String {
        return providerId
    }
    
    private func getDeviceId() -> String {
        if (!advertisingId.isEmpty) {
            return advertisingId
        }

        let identifierManager = ASIdentifierManager.shared()
        if identifierManager.isAdvertisingTrackingEnabled {
            return identifierManager.advertisingIdentifier.uuidString
        }
        
        return UIDevice.current.identifierForVendor?.uuidString ?? "UNKNOWN_DEVICE_ID"
    }
    
    private func updateUserState(data: Data?) {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Config.Date.format
        
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        guard let userData = data else {
            monitoring.error(EDMPError.userDataIsEmpty)
            return
        }
        
        guard let userState: UserStateStruct = try? decoder.decode(UserStateStruct.self, from: userData) else {
            monitoring.error(EDMPError.userDataParseError)
            return
        }
        
        self.setUserId(userId: userState.userId)
        self.setTimestamp(ts: String(userState.lastModifiedTimestamp))
        
        guard let databaseConnection = self.databaseStorage else {
            monitoring.error(EDMPError.databaseConnectFailed)
            return
        }
        
        do {
            if (userState.action == .REPLACE) {
                try databaseConnection.removeStorageData()
            }
            databaseConnection.setDefinitions(definitions: userState.definitions)
            databaseConnection.mergeEvents(newEvents: userState.events)
            databaseConnection.removeDefinitions(userState.deletedDefinitionIds)
            databaseConnection.removeEventsByDefinitions(userState.deletedDefinitionIds)
        } catch {
            monitoring.complete(error)
        }
    }
    
    private func removeOneTimeEvents() {
        do {
            guard let databaseConnection = self.databaseStorage else {
                monitoring.error(EDMPError.databaseConnectFailed)
                return
            }

            try databaseConnection.removeOneTimeEvents()
        } catch {
            monitoring.complete(error)
        }
    }
    
    private func calculateAudiences() {
        guard let events = self.databaseStorage?.getEvents(),
              let definitions = self.databaseStorage?.getDefinitions() else {
            monitoring.error(EDMPError.databaseConnectFailed)
            return
        }
        
        let matchedDefinitionIds = matchDefinitions(events: Array(events), definitions: Array(definitions))
        
        self.monitoring.log("matchedDefinitionIds: \(matchedDefinitionIds)")
        
        self.sendStatisticEvent(newDefinitionsIds: matchedDefinitionIds, definitions: definitions)
        
        self.definitionIds = matchedDefinitionIds
        self.setPrevDefinitionIds(matchedDefinitionIds)
        
        self.removeOneTimeEvents()
    }
    
    public func getDefinitionIds() -> String {
        return definitionIds.joined(separator: ",")
    }
    
    public func getCustomAdTargeting() -> [String: String] {
        let userId: String = getUserId() ?? ""
        return ["dxseg": getDefinitionIds(), "dxu": userId, "permutive": userId]
    }
    
    private func isSdkEnabled() -> Bool {
        return providerConfig?.providerSdk?.sdkIosEnabled ?? true
    }
    
    private func isIgnoreEvents(properties: EventRequestPropertiesStruct) -> Bool {
        do {
            return try self.providerConfig?.providerExclusions.first {rule in
                switch rule.type {
                case .URL_CONTAINS:
                    return try NSRegularExpression(pattern: rule.expression).firstMatch(
                        in: properties.url,
                        range: NSRange(properties.url.startIndex..., in: properties.url)
                    ) != nil
                case .URL_EXACTLY_MATCH:
                    return properties.url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == rule.expression.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                case .CATEGORY_EQUALS:
                    return properties.category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == rule.expression.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } != nil
        } catch {
            self.monitoring.error(EDMPError.configExpressionError)
            return false
        }
    }
    
    private func getConfig(completionHandler: @escaping (Any?) -> Void = {_ in }) {
        asyncEventsQueue.addTask { taskCompletion in
            do {
                self.monitoring.log("getConfig start")
                try Api.get(
                    url: Config.Api.configUrl,
                    pathParams: ["providerId": self.providerId]
                ) {(data, error) in
                    let decoder = JSONDecoder()
                    
                    guard let configData = data else {
                        self.monitoring.error(EDMPError.configDataIsEmpty)
                        return taskCompletion()
                    }
                    

                    guard let providerConfig: ProviderConfigStruct = try? decoder.decode(ProviderConfigStruct.self, from: configData) else {
                        self.monitoring.error(EDMPError.configDataParseError)
                        return taskCompletion()
                    }
                    
                    self.providerConfig = providerConfig
                    self.monitoring.setMonitoringConfig(providerConfig.providerMonitoring)
                    self.monitoring.log("getConfig end")

                    taskCompletion()
                }
            } catch {
                self.monitoring.complete(error)

                taskCompletion()
            }
        }
    }
    
    private func getState(completionHandler: @escaping (Any?) -> Void = {_ in }) {
        asyncEventsQueue.addTask { taskCompletion in
            do {
                self.monitoring.log("getState start")

                if (!self.isSdkEnabled()) {
                    self.monitoring.warning("Stop initialization! SDK is disabled, provider id: \(self.providerId)")
                    completionHandler(nil)
                    
                    return taskCompletion()
                }
                
                self.definitionIds = self.getPrevDefinitionIds()

                try Api.get(
                    url: Config.Api.stateUrl,
                    queryItems: ["ts": self.getTimestamp(), "dmpid": self.getUserId()]
                ) {(data, error) in
                    self.updateUserState(data: data)

                    PeriodicActions.runAction(
                        intervalSec: self.providerConfig?.pingFrequencySec,
                        actionName: "SEND_SYNC_EVENT",
                        action: self.sendSyncEvent
                    )

                    completionHandler(error)
                    
                    self.monitoring.log("getState end")

                    taskCompletion()
                }
            } catch {
                completionHandler(error)
                self.monitoring.complete(error)
                
                taskCompletion()
            }
        }
    }
    
    private func sendSyncEvent() {
        asyncEventsQueue.addTask { taskCompletion in
            self.monitoring.log("start sending sync event")
            guard let userId = self.getUserId() else {
                self.monitoring.error(EDMPError.userIdIsEmpty)
                
                return taskCompletion()
            }
            
            do {
                let eventBody = SyncEventRequestStruct(
                    event: EDMPSyncEvent.AUDIENCE_PING,
                    userId: userId,
                    providerId: self.providerId,
                    actualAudienceCodes: self.definitionIds,
                    srcMeta: self.sdkMetaData
                )
                
                try Api.post(
                    url: Config.Api.eventUrl,
                    queryItems: ["ts": self.getTimestamp(), "dmpid": userId],
                    body: eventBody
                ) {_,_ in 
                    self.monitoring.log("end sending sync event")
                    
                    taskCompletion()
                }
            } catch {
                self.monitoring.error(error)
                
                taskCompletion()
            }
        }
    }
    
    private func sendStatisticEvent(newDefinitionsIds: [String], definitions: [Definition]) {
        asyncEventsQueue.addTask { taskCompletion in
            guard let userId = self.getUserId() else {
                self.monitoring.error(EDMPError.userIdIsEmpty)
                
                return taskCompletion()
            }
            
            let enterAndExitDefinitionIds = getEnterAndExitDefinitionIds(oldDefinitionIds: self.definitionIds, newDefinitionIds: newDefinitionsIds, definitions: definitions)
            
            self.monitoring.log("enterDefinitionIds: \(enterAndExitDefinitionIds.enterIds), exitDefinitionIds: \(enterAndExitDefinitionIds.exitIds)")
            
            let enterEventRequest = enterAndExitDefinitionIds.enterIds.map { id in
                return StatisticEventRequestStruct(
                    event: EDMPStatisticEvent.AUDIENCE_ENTER,
                    userId: userId,
                    providerId: self.providerId,
                    audienceCode: id,
                    actualAudienceCodes: self.definitionIds,
                    srcMeta: self.sdkMetaData
                )
            }
            
            let exitEventRequest = enterAndExitDefinitionIds.exitIds.map { id in
                return StatisticEventRequestStruct(
                    event: EDMPStatisticEvent.AUDIENCE_EXIT,
                    userId: userId,
                    providerId: self.providerId,
                    audienceCode: id,
                    actualAudienceCodes: self.definitionIds,
                    srcMeta: self.sdkMetaData
                )
            }
            
            let events = enterEventRequest + exitEventRequest
            
            if (events.isEmpty) {
                self.monitoring.log("Event statistic requests skipped: event data is empty")

                return taskCompletion()
            }
            
            do {
                try Api.post(
                    url: Config.Api.eventUrl,
                    queryItems: ["ts": self.getTimestamp(), "dmpid": userId],
                    body: events
                ) {_,_ in 
                    taskCompletion()
                }
            } catch {
                self.monitoring.error(error)

                taskCompletion()
            }
        }
    }
    
    public func sendEvent(properties: EventRequestPropertiesStruct, completionHandler: @escaping (Any?) -> Void = {_ in}) {
        asyncEventsQueue.addTask { taskCompletion in
            if (!self.isSdkEnabled()) {
                self.monitoring.warning("Event sending has been ignored! SDK is disabled, provider id: \(self.providerId)")
                completionHandler(nil)
                
                return taskCompletion()
            }

            if (self.isIgnoreEvents(properties: properties)) {
                self.monitoring.warning("Event sending is disabled: \(properties)")
                completionHandler(nil)
                
                return taskCompletion()
            }
            
            guard let userId = self.getUserId() else {
                self.monitoring.error(EDMPError.userIdIsEmpty)
                // TODO: set error to handler
                completionHandler(nil)
                
                return taskCompletion()
            }
            
            let eventBody = EventRequestStruct(
                event: EDMPEvent.PAGE_VIEW,
                userId: userId,
                providerId: self.providerId,
                dxf: self.getDeviceId(),
                deviceId: self.getDeviceId(),
                properties: properties,
                srcMeta: self.sdkMetaData
            )
            
            do {
                try Api.post(
                    url: Config.Api.eventUrl,
                    queryItems: ["ts": self.getTimestamp(), "dmpid": userId],
                    body: eventBody
                ) {(data, error) in
                    self.updateUserState(data: data)
                    self.calculateAudiences()
                    completionHandler(error)
                    self.monitoring.complete()
                    
                    taskCompletion()
                }
            } catch {
                completionHandler(error)
                self.monitoring.complete(error)
                
                taskCompletion()
            }
        }
    }
    
    public func resetState () -> Void {
        asyncEventsQueue.addTask { taskCompletion in
            do {
                self.localStorage.removeObject(forKey: "userId")
                self.localStorage.removeObject(forKey: "ts")
                self.definitionIds = []
                try self.databaseStorage?.removeStorageData()
                
                taskCompletion()
            } catch {
                self.monitoring.complete(error)
                
                taskCompletion()
            }
        }
    }
}

public final class DataManagerProvider {
    let providerId: String
    let localStorage = UserDefaults.standard
    let monitoring: Monitoring
    let databaseStorage: Storage?

    var initIsComplete = false
    var providerConfig: ProviderConfigStruct?
    var eventRequestQueue: [EventQueueItem] = []
    var definitionIds: [String] = []
    
    public init(providerId: String, monitoringLabel: String?, completionHandler: @escaping (Any?) -> Void = {_ in}) {
        self.providerId = providerId
        self.monitoring = Monitoring(label: monitoringLabel)
        
        self.monitoring.log("Init with provider id: \(providerId)")
        do {
            if #available(iOS 12.0, *) {
                databaseStorage = try Storage()
            } else {
                throw EDMPError.databaseConnectFailed
            }
            self.getConfig(completionHandler: completionHandler)
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
            try databaseConnection.setDefinitions(definitions: userState.definitions)
            try databaseConnection.mergeEvents(newEvents: userState.events)
            try databaseConnection.removeDefinitions(userState.deletedDefinitionIds)
            try databaseConnection.removeEventsByDefinitions(userState.deletedDefinitionIds)
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
        do {
            try Api.get(
                url: Config.Api.configUrl,
                pathParams: ["providerId": self.providerId]
            ) {(data, error) in
                let decoder = JSONDecoder()
                
                guard let configData = data else {
                    self.monitoring.error(EDMPError.configDataIsEmpty)
                    return
                }

                guard let providerConfig: ProviderConfigStruct = try? decoder.decode(ProviderConfigStruct.self, from: configData) else {
                    self.monitoring.error(EDMPError.configDataParseError)
                    return
                }
                
                self.providerConfig = providerConfig
                
                self.monitoring.setMonitoringConfig(providerConfig.providerMonitoring)
                
                if (!self.isSdkEnabled()) {
                    self.monitoring.warning("Stop initialization! SDK is disabled, provider id: \(self.providerId)")
                    return completionHandler(nil)
                }

                self.getState(completionHandler: completionHandler)
            }
        } catch {
            completionHandler(error)
            monitoring.complete(error)
        }
    }
    
    private func getState(completionHandler: @escaping (Any?) -> Void = {_ in }) {
        do {
            self.definitionIds = self.getPrevDefinitionIds()

            try Api.get(
                url: Config.Api.stateUrl,
                queryItems: ["ts": getTimestamp(), "dmpid": getUserId()]
            ) {(data, error) in
                self.updateUserState(data: data)
                
                if (!self.initIsComplete) {
                    self.initIsComplete = true
                    self.eventRequestQueue.forEach { eventQueueItem in
                        self.sendEvent(
                            properties: eventQueueItem.properties,
                            completionHandler: eventQueueItem.callback
                        )
                    }
                }

                completionHandler(error)
            }
        } catch {
            completionHandler(error)
            monitoring.complete(error)
        }
    }
    
    private func sendStatisticEvent(newDefinitionsIds: [String], definitions: [Definition]) {
        guard let userId = getUserId() else {
            return monitoring.error(EDMPError.userIdIsEmpty)
        }
        
        let enterAndExitDefinitionIds = getEnterAndExitDefinitionIds(oldDefinitionIds: definitionIds, newDefinitionIds: newDefinitionsIds, definitions: definitions)

        self.monitoring.log("enterDefinitionIds: \(enterAndExitDefinitionIds.enterIds), exitDefinitionIds: \(enterAndExitDefinitionIds.exitIds)")

        enterAndExitDefinitionIds.enterIds.forEach { id in
            let eventBody = StatisticEventRequestStruct(
                event: EDMPStatisticEvent.AUDIENCE_ENTER,
                userId: userId,
                providerId: self.providerId,
                audienceCode: id,
                actualAudienceCodes: definitionIds
            )
            
            do {
                try Api.post(
                    url: Config.Api.eventUrl,
                    queryItems: ["ts": getTimestamp(), "dmpid": userId],
                    body: eventBody
                )
            } catch {
                monitoring.error(error)
            }
        }
        
        enterAndExitDefinitionIds.exitIds.forEach { id in
            let eventBody = StatisticEventRequestStruct(
                event: EDMPStatisticEvent.AUDIENCE_EXIT,
                userId: userId,
                providerId: self.providerId,
                audienceCode: id,
                actualAudienceCodes: definitionIds
            )
            
            do {
                try Api.post(
                    url: Config.Api.eventUrl,
                    queryItems: ["ts": getTimestamp(), "dmpid": userId],
                    body: eventBody
                )
            } catch {
                monitoring.error(error)
            }
        }
    }
    
    public func sendEvent(properties: EventRequestPropertiesStruct, completionHandler: @escaping (Any?) -> Void = {_ in}) {
        if (!self.isSdkEnabled()) {
            monitoring.warning("Event sending has been ignored! SDK is disabled, provider id: \(providerId)")
            return completionHandler(nil)
        }

        if (!self.initIsComplete) {
            self.eventRequestQueue.append(EventQueueItem(properties: properties, callback: completionHandler))
            return completionHandler(nil)
        }
        
        if (self.isIgnoreEvents(properties: properties)) {
            monitoring.warning("Event sending is disabled: \(properties)")
            return completionHandler(nil)
        }

        guard let userId = getUserId() else {
            monitoring.error(EDMPError.userIdIsEmpty)
            // TODO: set error to handler
            return completionHandler(nil)
        }

        let eventBody = EventRequestStruct(
            event: EDMPEvent.PAGE_VIEW,
            userId: userId,
            providerId: self.providerId,
            properties: properties
        )
        
        do {
            try Api.post(
                url: Config.Api.eventUrl,
                queryItems: ["ts": getTimestamp(), "dmpid": userId],
                body: eventBody
            ) {(data, error) in
                self.updateUserState(data: data)
                self.calculateAudiences()
                completionHandler(error)
                self.monitoring.complete()
            }
        } catch {
            completionHandler(error)
            monitoring.complete(error)
        }
    }
    
    public func resetState () -> Void {
        do {
            localStorage.removeObject(forKey: "userId")
            localStorage.removeObject(forKey: "ts")
            self.definitionIds = []
            try self.databaseStorage?.removeStorageData()
        } catch {
            monitoring.complete(error)
        }
    }
}

public final class DataManagerProvider {
    let providerId: String
    let localStorage = UserDefaults.standard
    let monitroing = Monitoring(.Errors)
    let databaseStorage: Storage?

    var initIsComplete = false
    var eventRequestQueue: [EventQueueItem] = []
    var definitionIds: [String] = []
    
    public init(providerId: String, completionHandler: @escaping (Any?) -> Void = {_ in}) {
        self.providerId = providerId
        
        self.monitroing.log("Init with provider id: \(providerId)")
        do {
            if #available(iOS 12.0, *) {
                databaseStorage = try Storage()
            } else {
                throw EDMPError.databaseConnectFailed
            }
            self.getState(completionHandler: completionHandler)
        } catch {
            databaseStorage = nil
            self.monitroing.complete(EDMPError.databaseConnectFailed)
        }
    }
    
    private func setUserId(userId: String) {
        localStorage.set(userId, forKey: "userId")
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
            monitroing.error(EDMPError.userDataIsEmpty)
            return
        }
        
        guard let userState: UserStateStruct = try? decoder.decode(UserStateStruct.self, from: userData) else {
            monitroing.error(EDMPError.userDataParseError)
            return
        }
        
        self.setUserId(userId: userState.userId)
        self.setTimestamp(ts: String(userState.lastModifiedTimestamp))
        
        guard let databaseConnection = self.databaseStorage else {
            monitroing.error(EDMPError.databaseConnectFailed)
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
            monitroing.complete(error)
        }
    }
    
    private func removeOneTimeEvents() {
        do {
            guard let databaseConnection = self.databaseStorage else {
                monitroing.error(EDMPError.databaseConnectFailed)
                return
            }

            try databaseConnection.removeOneTimeEvents()
        } catch {
            monitroing.complete(error)
        }
    }
    
    private func calculateAudiences() {
        guard let events = self.databaseStorage?.getEvents(),
              let definitions = self.databaseStorage?.getDefinitions() else {
            monitroing.error(EDMPError.databaseConnectFailed)
            return
        }
        
        let matchedDefinitionIds = matchDefinitions(events: Array(events), definitions: Array(definitions))
        
        self.monitroing.log("matchedDefinitionIds: \(matchedDefinitionIds)")
        
        self.sendStatisticEvent(newDefinitionsIds: matchedDefinitionIds, definitions: definitions)
        
        self.definitionIds = matchedDefinitionIds
        self.setPrevDefinitionIds(matchedDefinitionIds)
        
        self.removeOneTimeEvents()
    }
    
    public func getDefinitionIds() -> String {
        return definitionIds.joined(separator: ",")
    }
    
    private func getState(completionHandler: @escaping (Any?) -> Void = {_ in }) {
        do {
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
            monitroing.complete(error)
        }
    }
    
    private func sendStatisticEvent(newDefinitionsIds: [String], definitions: [Definition]) {
        guard let userId = getUserId() else {
            return monitroing.error(EDMPError.userIdIsEmpty)
        }
        
        let oldDefinitionIds = self.getPrevDefinitionIds()
        
        let enterAndExitDefinitionIds = getEnterAndExitDefinitionIds(oldDefinitionIds: oldDefinitionIds, newDefinitionIds: newDefinitionsIds, definitions: definitions)

        self.monitroing.log("enterDefinitionIds: \(enterAndExitDefinitionIds.enterIds), exitDefinitionIds: \(enterAndExitDefinitionIds.exitIds)")

        enterAndExitDefinitionIds.enterIds.forEach { id in
            let eventBody = StatisticEventRequestStruct(
                event: EDMPStatisticEvent.AUDIENCE_ENTER,
                userId: userId,
                providerId: self.providerId,
                audienceCode: id,
                actualAudienceCodes: oldDefinitionIds
            )
            
            do {
                try Api.post(
                    url: Config.Api.eventUrl,
                    queryItems: ["ts": getTimestamp(), "dmpid": userId],
                    body: eventBody
                )
            } catch {
                monitroing.error(error)
            }
        }
        
        enterAndExitDefinitionIds.exitIds.forEach { id in
            let eventBody = StatisticEventRequestStruct(
                event: EDMPStatisticEvent.AUDIENCE_EXIT,
                userId: userId,
                providerId: self.providerId,
                audienceCode: id,
                actualAudienceCodes: oldDefinitionIds
            )
            
            do {
                try Api.post(
                    url: Config.Api.eventUrl,
                    queryItems: ["ts": getTimestamp(), "dmpid": userId],
                    body: eventBody
                )
            } catch {
                monitroing.error(error)
            }
        }
    }
    
    public func sendEvent(properties: EventRequestPropertiesStruct, completionHandler: @escaping (Any?) -> Void = {_ in}) {
        if (!self.initIsComplete) {
            self.eventRequestQueue.append(EventQueueItem(properties: properties, callback: completionHandler))
            return
        }

        guard let userId = getUserId() else {
            return monitroing.error(EDMPError.userIdIsEmpty)
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
                self.monitroing.complete()
            }
        } catch {
            completionHandler(error)
            monitroing.complete(error)
        }
    }
    
    public func resetState () -> Void {
        do {
            localStorage.removeObject(forKey: "userId")
            localStorage.removeObject(forKey: "ts")
            self.definitionIds = []
            try self.databaseStorage?.removeStorageData()
        } catch {
            monitroing.complete(error)
        }
    }
}

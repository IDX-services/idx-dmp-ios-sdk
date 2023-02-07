public final class DataManagerProvider {
    let providerId: String
    let localStorage = UserDefaults.standard
    let logger = Logger()
    let databaseStorage: Storage?

    var initIsComplete = false
    var eventRequestQueue: [EventQueueItem] = []
    var definitionIds: [String] = []
    
    public init(providerId: String, completionHandler: @escaping () -> Void = {}) {
        self.providerId = providerId
        
        do {
            databaseStorage = try Storage()
            self.getState(completionHandler: completionHandler)
        } catch {
            databaseStorage = nil
            self.logger.error(EDMPError.databaseConnectFailed)
        }
    }
    
    private func setUserId(userId: String) {
        localStorage.set(userId, forKey: "userId")
    }
    
    func getUserId() -> String? {
        return localStorage.string(forKey: "userId")
    }
    
    private func setTimestamp(ts: String) {
        localStorage.set(ts, forKey: "ts")
    }
    
    func getTimestamp() -> String? {
        return localStorage.string(forKey: "ts")
    }
    
    func getProviderId() -> String {
        return providerId
    }
    
    private func updateUserState(data: Data?) {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Config.Date.format
        
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        guard let userData = data else {
            logger.error(EDMPError.userDataIsEmpty)
            return
        }
        
        guard let userState: UserStateStruct = try? decoder.decode(UserStateStruct.self, from: userData) else {
            logger.error(EDMPError.userDataParseError)
            return
        }
        
        self.setUserId(userId: userState.userId)
        self.setTimestamp(ts: String(userState.lastModifiedTimestamp))
        
        guard let databaseConnection = self.databaseStorage else {
            logger.error(EDMPError.databaseConnectFailed)
            return
        }
        
        do {
            try databaseConnection.setDefinitions(definitions: userState.definitions)
            try databaseConnection.mergeEvents(newEvents: userState.events)
        } catch {
            logger.error(error)
        }
    }
    
    private func calculateAudiences() {
        guard let events = self.databaseStorage?.getEvents(),
              let definitions = self.databaseStorage?.getDefinitions() else {
            logger.error(EDMPError.databaseConnectFailed)
            return
        }
        
        self.definitionIds = matchDefinitions(events: Array(events), definitions: Array(definitions))
    }
    
    public func getDefinitionIds() -> String {
        return definitionIds.joined(separator: ",")
    }
    
    private func getState(completionHandler: @escaping () -> Void = {}) {
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
                
                completionHandler()
            }
        } catch {
            logger.error(error)
        }
    }
    
    public func sendEvent(properties: EventRequestPropertiesStruct, completionHandler: @escaping () -> Void = {}) {
        if (!self.initIsComplete) {
            self.eventRequestQueue.append(EventQueueItem(properties: properties, callback: completionHandler))
            return
        }

        guard let userId = getUserId() else {
            return logger.error(EDMPError.userIdIsEmpty)
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
                completionHandler()
            }
        } catch {
            logger.error(error)
        }
    }
}

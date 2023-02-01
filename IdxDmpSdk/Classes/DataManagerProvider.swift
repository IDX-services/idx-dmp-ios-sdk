public final class DataManagerProvider {
    let providerId: String
    let localStorage = UserDefaults.standard
    let databaseStorage: Storage

    var definitionIds: [String] = []
    
    public init(providerId: String) {
        self.providerId = providerId
        databaseStorage = Storage()
    }
    
    func setUserId(userId: String) {
        localStorage.set(userId, forKey: "userId")
    }
    
    func getUserId() -> String? {
        return localStorage.string(forKey: "userId")
    }
    
    func setTimestamp(ts: String) {
        localStorage.set(ts, forKey: "ts")
    }
    
    func getTimestamp() -> String? {
        return localStorage.string(forKey: "ts")
    }
    
    func getProviderId() -> String {
        return providerId
    }
    
    func parseUserState(data: Data) -> UserStateStruct? {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Config.Date.format
        
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        guard let userState: UserStateStruct = try? decoder.decode(UserStateStruct.self, from: data) else {
            print("Parse user state response error")
            return nil
        }
        
        return userState
    }
    
    public func getDefinitionIds() -> String {
        return definitionIds.joined(separator: ",")
    }
    
    public func getState(completionHandler: @escaping () -> Void = {}) {
        Api.get(
            url: Config.Api.stateUrl,
            queryItems: ["ts": getTimestamp(), "dmpid": getUserId()]
        ) {(data, error) in
            if let userState = self.parseUserState(data: data) {
                self.setUserId(userId: userState.userId)
                self.setTimestamp(ts: String(userState.lastModifiedTimestamp))
                
                self.databaseStorage.setDefinitions(definitions: userState.definitions)
                self.databaseStorage.mergeEvents(newEvents: userState.events)
            }
            
            completionHandler()
        }
    }
    
    public func sendEvent(properties: EventRequestPropertiesStruct, completionHandler: @escaping () -> Void = {}) {
        guard let userId = getUserId() else {
            return print("userId is not found")
        }

        let eventBody = EventRequestStruct(
            event: EDMPEvent.PAGE_VIEW,
            userId: userId,
            providerId: self.providerId,
            properties: properties
        )

        Api.post(
            url: Config.Api.eventUrl,
            queryItems: ["ts": getTimestamp(), "dmpid": userId],
            body: eventBody
        ) {(data, error) in
            if let userState = self.parseUserState(data: data) {
                self.setUserId(userId: userState.userId)
                self.setTimestamp(ts: String(userState.lastModifiedTimestamp))

                self.databaseStorage.setDefinitions(definitions: userState.definitions)
                self.databaseStorage.mergeEvents(newEvents: userState.events)
            }
            
            let events = self.databaseStorage.getEvents()
            let definitions = self.databaseStorage.getDefinitions()

            self.definitionIds = matchDefinitions(events: Array(events), definitions: Array(definitions))
            
            completionHandler()
        }
    }
}

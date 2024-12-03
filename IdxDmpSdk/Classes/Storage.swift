import CoreData

func getEventComputedId(eventStruct: EventStruct) -> String {
    return "\(eventStruct.defId)_\(eventStruct.behaviourCode)"
}

final class Storage {
    private let dbConnector: DBConnector
    private let monitoring: Monitoring

    public init(monitoring: Monitoring) throws {
        do {
            self.monitoring = monitoring
            
            self.dbConnector = try DBConnector.instance.get()
        } catch {
            throw EDMPError.databaseConnectFailed
        }
    }
    
    public func setDefinitions(definitions: [DefinitionStruct]) {
        dbConnector.runTransaction { context in
            do {
                definitions.forEach { definitionStruct in
                    let definition = Definition(context: context)
                    definition.setData(definitionStruct: definitionStruct)
                }

                try context.save()
            } catch {
                self.monitoring.error(EDMPError.setDefinitionsFailed)
            }
        }
    }
    
    public func getDefinitions(_ callback: @escaping ([Definition]) -> Void) -> Void {
        dbConnector.runTransaction { context in
            do {
                callback(try context.fetch(Definition.fetchRequest()))
            } catch {
                callback([])
            }
        }
    }
    
    public func removeDefinitions(_ definitionIds: [String]) {
        dbConnector.runTransaction { context in
            do {
                if (definitionIds.isEmpty) {
                    return
                }
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Definition")
                request.predicate = NSPredicate(
                    format: "defId IN %@", definitionIds
                )
                
                try context.execute(NSBatchDeleteRequest(fetchRequest: request))
                try context.save()
            } catch {
                self.monitoring.error(EDMPError.removePartialEvents)
            }
        }
    }
    
    public func removeAllDefinitions() {
        dbConnector.runTransaction { context in
            do {
                try context.execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Definition")))
                try context.save()
            } catch {
                self.monitoring.error(EDMPError.removeAllDefinitions)
            }
        }
    }
    
    public func setEvents(events: [EventStruct]) {
        dbConnector.runTransaction { context in
            do {
                events.forEach { eventStruct in
                    let event = Event(context: context)
                    event.setData(eventStruct: eventStruct)
                }
                
                try context.save()
            } catch {
                self.monitoring.error(EDMPError.setEventsFailed)
            }
        }
    }
    
    public func getEvents(_ callback: @escaping ([Event]) -> Void) -> Void {
        dbConnector.runTransaction { context in
            do {
                callback(try context.fetch(Event.fetchRequest()))
            } catch {
                callback([])
            }
        }
    }
    
    public func removeEventsByDefinitions(_ definitionIds: [String]) {
        dbConnector.runTransaction { context in
            do {
                if (definitionIds.isEmpty) {
                    return
                }
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
                request.predicate = NSPredicate(
                    format: "defId IN %@", definitionIds
                )
                
                try context.execute(NSBatchDeleteRequest(fetchRequest: request))
                try context.save()
            } catch {
                self.monitoring.error(EDMPError.removePartialEvents)
            }
        }
    }
    
    public func removeOneTimeEvents() throws {
        self.getDefinitions({ definitions in
            let oneTimeDefinitionIds = definitions
                .filter({ $0.type == EDefinitionType.CURRENT_PAGE })
                .map({ return $0.defId })

            self.removeEventsByDefinitions(oneTimeDefinitionIds)
        })
    }
    
    public func removeAllEvents() {
        dbConnector.runTransaction { context in
            do {
                try context.execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Event")))
                try context.save()
            } catch {
                self.monitoring.error(EDMPError.removeAllEvents)
            }
        }
    }
    
    public func mergeEvents(newEvents: [EventStruct]) {
        self.getEvents({ oldEvents in
            self.dbConnector.runTransaction { context in
                do {
                    newEvents.forEach { eventStruct in
                        if let currentOldEvent: Event = oldEvents.first(
                            where: {$0.computedId == getEventComputedId(eventStruct: eventStruct)}
                        ) {
                            currentOldEvent.timestamps = currentOldEvent.timestamps
                                .addingObjects(from: eventStruct.timestamps)
                                .sorted {a, b in (a as! Int) > (b as! Int)} as NSArray
                            let removeCount = currentOldEvent.timestamps.count - Config.Constant.maxEventCount
                            if (removeCount > 0) {
                                currentOldEvent.timestamps = currentOldEvent.timestamps.dropLast(removeCount) as NSArray
                            }
                        } else {
                            let event = Event(context: context)
                            event.setData(eventStruct: eventStruct)
                        }
                    }

                    try context.save()
                } catch {
                    self.monitoring.error(EDMPError.mergeEventsFailed)
                }
            }
        })
    }
    
    public func removeStorageData() throws {
        self.removeAllEvents()
        self.removeAllDefinitions()
    }
}

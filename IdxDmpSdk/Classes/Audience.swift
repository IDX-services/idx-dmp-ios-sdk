import Foundation

func substractDate(unit: EDateTimeUnit, value: Int) -> Int {
    let negativeValue = value < 0 ? value : value * -1
    let byAdding: Calendar.Component

    switch unit {
    case .HOURS:
        byAdding = Calendar.Component.hour
    case .DAYS:
        byAdding = Calendar.Component.day
    case .WEEKS:
        byAdding = Calendar.Component.weekOfYear
    case .MONTHS:
        byAdding = Calendar.Component.month
    }
    
    return Int(Calendar.current.date(byAdding: byAdding, value: negativeValue, to: Date())!.timeIntervalSince1970)
}

func matchDuration(behaviour: Behaviour, eventTimestamps: [Int]) -> [Int] {
    switch behaviour.durationOperator {
    case .ALL:
        return eventTimestamps
    case .LAST:
        if (behaviour.durationUnit == nil || behaviour.durationValue == nil) {
            return []
        }
        let substractTimestamp = substractDate(unit: behaviour.durationUnit!, value: behaviour.durationValue!)
        return eventTimestamps.filter({ $0 > substractTimestamp })
    case .AFTER:
        return eventTimestamps.filter({
            behaviour.durationMinDate != nil
            && $0 > Int(behaviour.durationMinDate!.timeIntervalSince1970)
        })
    case .BEFORE:
        return eventTimestamps.filter({
            behaviour.durationMaxDate != nil
            && $0 < Int(behaviour.durationMaxDate!.timeIntervalSince1970)
        })
    case .BETWEEN:
        return eventTimestamps.filter({
            behaviour.durationMinDate != nil
            && behaviour.durationMaxDate != nil
            && $0 > Int(behaviour.durationMinDate!.timeIntervalSince1970)
            && $0 < Int(behaviour.durationMaxDate!.timeIntervalSince1970)
        })
    default:
        return []
    }
}

func matchFrequency(behaviour: Behaviour, eventTimestamps: [Int]) -> Bool {
    if (behaviour.frequencyOperator == nil) {
        return false
    }
    
    switch behaviour.frequencyOperator {
    case .EXACTLY:
        return eventTimestamps.count == behaviour.frequencyValue
    case .BETWEEN:
        return behaviour.frequencyMin != nil
            && behaviour.frequencyMax != nil
            && eventTimestamps.count >= behaviour.frequencyMin!
            && eventTimestamps.count <= behaviour.frequencyMax!
    case .AT_MOST:
        return behaviour.frequencyMax != nil && eventTimestamps.count <= behaviour.frequencyMax!
    case .AT_LEAST:
        return behaviour.frequencyMin != nil && eventTimestamps.count >= behaviour.frequencyMin!
    case .NOT_DEFINED:
        return true
    default:
        return false
    }
}

func matchDefinitions(events: [Event], definitions: [Definition]) -> [String] {
    let definitonIds = definitions.filter { definition in
        let eventsByDefinition = events.filter { event in
            return event.defId == definition.defId
        }
        
        if (eventsByDefinition.count < 1) {
            return false
        }
        
        if (definition.behaviourOperators.count < definition.behaviours.count - 1) {
            // TODO send fail message to BE
            return false
        }
        
        var isMatch = true
        
        if (definition.type != EDefinitionType.CURRENT_PAGE) {
            definition.behaviours.sorted(by: { $0.ordinalNum < $1.ordinalNum }).enumerated().forEach({ (index, behaviour) in
                let behaviourOperator = index > 0 && definition.behaviourOperators.count > 0
                    ? definition.behaviourOperators[index - 1]
                    : EBehaviourOperator.AND
                
                if (isMatch && behaviourOperator == EBehaviourOperator.OR) {
                    return
                }
                
                if (!isMatch && behaviourOperator == EBehaviourOperator.AND) {
                    return
                }
                
                var eventBehaviourTimestamps: [Int] = []
                eventsByDefinition.forEach({ event in
                    if (event.behaviourCode == behaviour.code) {
                        eventBehaviourTimestamps.append(contentsOf: event.timestamps as! [Int])
                    }
                })
                
                let matchedTimestamps: [Int] =
                    matchDuration(behaviour: behaviour, eventTimestamps: eventBehaviourTimestamps)
                
                let frequencyIsMatched = matchFrequency(behaviour: behaviour, eventTimestamps: matchedTimestamps)

                isMatch = frequencyIsMatched && matchedTimestamps.count > 0
            })
        }

        return isMatch
    }.map({ return $0.code })
    
    return Array(Set(definitonIds))
}

private func isDefinitionDebugEnabled(id: String, definitions: [Definition]) -> Bool {
    return definitions
        .filter { $0.code == id }
        .sorted(by: { $0.revision > $1.revision })
        .first?.debugEnabled ?? false
}

func getEnterAndExitDefinitionIds(
    oldDefinitionIds: [String],
    newDefinitionIds: [String],
    definitions: [Definition]) -> EnterAndExitDefinitionIds
{
    let enterIds = newDefinitionIds.filter { id in
        return !oldDefinitionIds.contains(id) && isDefinitionDebugEnabled(id: id, definitions: definitions)
    }

    let exitIds = oldDefinitionIds.filter { id in
        return !newDefinitionIds.contains(id) && isDefinitionDebugEnabled(id: id, definitions: definitions)
    }

    return EnterAndExitDefinitionIds(enterIds: enterIds, exitIds: exitIds)
}

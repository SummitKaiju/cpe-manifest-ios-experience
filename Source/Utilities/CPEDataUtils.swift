//
//  CPEDataUtils.swift
//

import Foundation
import CPEData

struct CPEDataUtils {
    
    static var numPersonJobFunctions: Int {
        return (CPEXMLSuite.current?.manifest.peopleByJobFunction?.count ?? 0)
    }
    
    static var people: [PersonJobFunction: [Person]]? {
        return CPEXMLSuite.current?.manifest.peopleByJobFunction
    }
    
    static var personJobFunctions: [PersonJobFunction]? {
        return people?.keys.sorted()
    }
    
    static func titleForPeople(with jobFunction: PersonJobFunction = .actor) -> String {
        return (CPEXMLSuite.current?.manifest.timedEvents?.first(where: { timedEvent in
            return (timedEvent.person?.jobFunction == jobFunction)
        })?.experience?.title ?? "")
    }
    
    static func titleForPerson(with jobFunction: PersonJobFunction) -> String {
        let pluralTitle = titleForPeople(with: jobFunction)
        switch pluralTitle {
        case String.localize("label.actors"):       return String.localize("label.actor")
        case String.localize("label.characters"):   return String.localize("label.character")
        case String.localize("label.heroes"):       return String.localize("label.hero")
        case String.localize("label.avatars"):      return String.localize("label.avatar")
        default:                                    return pluralTitle
        }
    }

}

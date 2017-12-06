//
//  CPEDataUtils.swift
//

import Foundation
import CPEData

struct CPEDataUtils {

    private static var _peopleExperienceName: String?
    static var peopleExperienceName: String {
        if _peopleExperienceName == nil {
            if let title = CPEXMLSuite.current?.manifest.timedEvents?.first(where: { $0.isType(.person) })?.experience?.title, title.count > 0 {
                _peopleExperienceName = title
            } else {
                _peopleExperienceName = String.localize("label.actors")
            }
        }

        return _peopleExperienceName!
    }
    
    static var personExperienceName: String {
        switch (peopleExperienceName) {
        case String.localize("label.actors"):
            return String.localize("label.actor")
            
        case String.localize("label.characters"):
            return String.localize("label.character")
            
        default:
            return peopleExperienceName
        }
    }

    private static var _peopleForDisplay: [Person]?
    static var peopleForDisplay: [Person]? {
        if _peopleForDisplay == nil {
            if let people = CPEXMLSuite.current?.manifest.people {
                var peopleForDisplay = [Person]()
                for person in people {
                    if let jobs = person.jobs, jobs.contains(where: { $0.function == .actor || $0.function == .keyCharacter }) {
                        peopleForDisplay.append(person)
                    }
                }

                if peopleForDisplay.count > 0 {
                    _peopleForDisplay = peopleForDisplay
                }
            }
        }

        return _peopleForDisplay
    }

    static var hasPeopleForDisplay: Bool {
        return peopleForDisplay != nil
    }

    static var numPeopleForDisplay: Int {
        return (peopleForDisplay?.count ?? 0)
    }

    static func reset() {
        _peopleExperienceName = nil
        _peopleForDisplay = nil
    }

}

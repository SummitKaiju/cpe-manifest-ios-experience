//
//  StringUtils.swift
//

import Foundation
import UIKit

extension String {

    func removeAll(_ characters: [Character]) -> String {
        return String(self.filter({ !characters.contains($0) }))
    }

    func htmlDecodedString() -> String {
        if let encodedData = self.data(using: String.Encoding.utf8) {
            let attributedOptions: [String: AnyObject] = [convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType): convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.html) as AnyObject, convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.characterEncoding): String.Encoding.utf8 as AnyObject]
            do {
                let attributedString = try NSAttributedString(data: encodedData, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary(attributedOptions), documentAttributes: nil)
                return attributedString.string
            } catch {
                print("Error decoding HTML string: \(error)")
                return self
            }
        }

        return self
    }

    static func localize(_ key: String) -> String {
        return NSLocalizedString(key, tableName: "CPEManifestExperience", bundle: Bundle.frameworkResources, value: "", comment: "")
    }

    static func localize(_ key: String, variables: [String: String?]) -> String {
        var localizedString = String.localize(key)
        for (variableName, variableValue) in variables {
            localizedString = localizedString.replacingOccurrences(of: "%{" + variableName + "}", with: (variableValue ?? ""))
        }

        return localizedString
    }

    static func localizePlural(_ singularKey: String, pluralKey: String, count: Int) -> String {
        return localize(count == 1 ? singularKey : pluralKey, variables: ["count": String(count)])
    }

    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }

    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }

    subscript (r: Range<Int>) -> String {
        let start = self.index(startIndex, offsetBy: r.lowerBound)
        let end = index(start, offsetBy: r.upperBound - r.lowerBound)
        return String(self[start ..< end])
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringDocumentAttributeKey(_ input: NSAttributedString.DocumentAttributeKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringDocumentType(_ input: NSAttributedString.DocumentType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringDocumentReadingOptionKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.DocumentReadingOptionKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.DocumentReadingOptionKey(rawValue: key), value)})
}

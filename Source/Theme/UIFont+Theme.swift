//
//  UIFont+Theme.swift
//

import UIKit

extension UIFont {

    @objc static func themeFont(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "Roboto", size: size) {
            return font
        }

        return UIFont.systemFont(ofSize: size)
    }

    @objc static func themeCondensedFont(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "RobotoCondensed-Regular", size: size) {
            return font
        }

        return UIFont.systemFont(ofSize: size)
    }

    @objc static func themeCondensedBoldFont(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "RobotoCondensed-Bold", size: size) {
            return font
        }

        return UIFont.boldSystemFont(ofSize: size)
    }

    @objc public static func loadFonts() {
        registerFont(withFileName: "Roboto-Regular", type: "ttf")
        registerFont(withFileName: "RobotoCondensed-Bold", type: "ttf")
        registerFont(withFileName: "RobotoCondensed-Italic", type: "ttf")
        registerFont(withFileName: "RobotoCondensed-Regular", type: "ttf")
    }

    @objc static func registerFont(withFileName fileName: String, type: String) {
        if let fontPath = Bundle.frameworkResources.path(forResource: fileName, ofType: type), let fontData = NSData(contentsOfFile: fontPath), let dataProvider = CGDataProvider(data: fontData) {
            let fontRef = CGFont(dataProvider)
            var errorRef: Unmanaged<CFError>? = nil
            if CTFontManagerRegisterGraphicsFont(fontRef!, &errorRef) == false {
                print("Failed to register font - register graphics font failed - this font may have already been registered in the main bundle.")
            }
        }
    }

}

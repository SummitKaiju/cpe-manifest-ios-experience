//
//  UIStoryboardUtils.swift
//

import UIKit

extension UIStoryboard {

    private struct Constants {
        static let StoryboardNameTablet = "Main_iPad"
        static let StoryboardNameMobile = "Main_iPhone"
    }

    @objc static func viewController(for viewControllerClass: AnyClass) -> UIViewController {
        return UIStoryboard(name: (DeviceType.IS_IPAD ? Constants.StoryboardNameTablet : Constants.StoryboardNameMobile), bundle: Bundle.frameworkResources).instantiateViewController(withIdentifier: String(describing: viewControllerClass))
    }

}

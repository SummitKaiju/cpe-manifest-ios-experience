//
//  URLUtils.swift
//

import UIKit
import SafariServices

public enum URLLaunchType {
    case browser
    case itunes
}

extension URL {

    public func promptLaunch(type: URLLaunchType = .browser, cancelHandler: (() -> Void)? = nil) {
        let alertMessage = (type == .itunes ? String.localize("info.leaving_app.message_itunes") : String.localize("info.leaving_app.message"))
        if #available(iOS 9.0, *) {
            if type == .itunes {
                promptLaunch(withMessage: alertMessage, cancelHandler: cancelHandler)
            } else {
                let safariViewController = SFSafariViewController(url: self)
                UIViewController.top?.present(safariViewController, animated: true, completion: nil)
            }
        } else {
            promptLaunch(withMessage: alertMessage, cancelHandler: cancelHandler)
        }
    }

    public func promptLaunch(withMessage message: String?, cancelHandler: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: String.localize("info.leaving_app.title"), message: message, preferredStyle: UIAlertController.Style.alert)

        alertController.addAction(UIAlertAction(title: String.localize("label.no"), style: .cancel, handler: { (_) -> Void in
            cancelHandler?()
        }))

        alertController.addAction(UIAlertAction(title: String.localize("label.yes"), style: .default, handler: { (_) -> Void in
            UIApplication.shared.openURL(self)
        }))

        alertController.show()
    }

}

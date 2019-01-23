//
//  UIAlertControllerUtils.swift
//

import UIKit

extension UIAlertController {

    @objc func show() {
        show(true)
    }

    @objc func show(_ animated: Bool) {
        UIViewController.top?.present(self, animated: animated, completion: nil)
    }

}

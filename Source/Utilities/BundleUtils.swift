//
//  BundleUtils.swift
//

import Foundation

extension Bundle {

    static var frameworkResources: Bundle {
        
        // CocoaPod using bundles
        if let resourcesBundleURL = Bundle(for: HomeViewController.self).url(forResource: "CPEExperience", withExtension: "bundle"), let resourcesBundle = Bundle(url: resourcesBundleURL) {
            return resourcesBundle
        }
        
        // Init resourcesBundle
        let resourcesBundle = Bundle(for: HomeViewController.self)
        
        // Carthage / Dynamic Framework
        if !resourcesBundle.bundlePath.isEmpty && resourcesBundle.bundleURL.pathExtension == "framework" {
            return resourcesBundle
        }

        // All Else
        return Bundle.main
    }

}

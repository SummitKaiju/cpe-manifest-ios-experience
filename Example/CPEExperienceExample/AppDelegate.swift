//
//  AppDelegate.swift
//

import UIKit
import CPEExperience

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Config.load()
        
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: .applicationWillEnterForeground, object: nil)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: .applicationWillResignActive, object: nil)
    }

}

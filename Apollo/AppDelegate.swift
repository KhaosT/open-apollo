//
//  AppDelegate.swift
//  Apollo
//
//  Created by Khaos Tian on 9/26/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit
import SpotifyServices

@available(iOS 13.0, *)
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.tintColor = Color.green
        
        if let currentConfiguration = ConfigurationServices.shared.currentConfiguration {
            WatchCommunicationManager.shared.start()
            SpotifyServiceProvider.shared.configure(with: currentConfiguration)
            let viewController = SessionLoadingViewController()
            let navigationController = BaseNavigationViewController()
            navigationController.viewControllers = [viewController]
            window.rootViewController = navigationController
        } else {
            let viewController = WelcomeViewController()
            let navigationController = BaseNavigationViewController()
            navigationController.viewControllers = [viewController]
            window.rootViewController = navigationController
        }
        
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}


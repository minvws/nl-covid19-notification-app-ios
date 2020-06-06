/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow()

        guard let window = window else {
            fatalError("AppDelegate - Window not found!")
        }
        
        if #available(iOS 13.5, *) {
            window.rootViewController = NavigationController(rootViewController: OnboardingStepViewController(index: 0))
        } else {
            window.rootViewController = UIStoryboard(name: "UnsupportedOs", bundle: nil)
                .instantiateInitialViewController()
        }
        window.makeKeyAndVisible()
        
        return true
    }

}


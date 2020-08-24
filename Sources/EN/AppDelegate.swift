/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(BackgroundTasks)
    import BackgroundTasks
#endif

import ENFoundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Note: The following needs to be set before application:didFinishLaunchingWithOptions: returns
        let unc = UNUserNotificationCenter.current()
        unc.delegate = self

        if #available(iOS 13.5, *) {
            [
                "nl.rijksoverheid.en.background-refresh.exposure-notification",
                "nl.rijksoverheid.en.background-decoy-stop-keys",
                "nl.rijksoverheid.en.background-decoy-sequence",
                "nl.rijksoverheid.en.background-decoy-register"
            ]
            .forEach { identifier in
                BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
                    self.handle(backgroundTask: task)
                }
            }
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func setBridge(bridge: ENCoreBridge?) {
        self.bridge = bridge
    }

    // MARK: - Private

    private var bridge: ENCoreBridge?

    @available(iOS 13, *)
    private func handle(backgroundTask: BGTask) {
        guard let bridge = bridge else {
            return print("🔥 ENCoreBridge is `nil`")
        }
        bridge.handleBackgroundTask(backgroundTask)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> ()) {
        completionHandler(.alert)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> ()) {
        bridge?.didReceiveRemoteNotification(center, didReceive: response, withCompletionHandler: completionHandler)
    }
}

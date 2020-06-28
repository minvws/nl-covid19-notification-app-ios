/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var pushNotificationHandler: ((UNUserNotificationCenter, UNNotificationResponse, @escaping () -> ()) -> ())?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        guard #available(iOS 13.0, *) else {
            let window = UIWindow(frame: UIScreen.main.bounds)
            self.window = window

            window.rootViewController = RequiresUpdateViewController()
            window.makeKeyAndVisible()

            return true
        }
        // Note: The following needs to be set before application:didFinishLaunchingWithOptions: returns
        let unc = UNUserNotificationCenter.current()
        unc.delegate = self

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "nl.rijksoverheid.en.background_task", using: nil) { task in
            self.handle(backgroundTask: task)
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

    // MARK: - Private

    @available(iOS 13, *)
    private func handle(backgroundTask: BGTask) {
        // Note: This needs to be run on the main thread
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let sceneDelegate = windowScene.delegate as? SceneDelegate else {
                return print("🔥 SceneDelegate is `nil`")
            }
            sceneDelegate.handle(backgroundTask: backgroundTask)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> ()) {
        completionHandler(.alert)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> ()) {
        if let pushNotificationHandler = pushNotificationHandler {
            pushNotificationHandler(center, response, completionHandler)
        }
    }
}

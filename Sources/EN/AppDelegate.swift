/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(BackgroundTasks)
    import BackgroundTasks
#endif

import ENCore
import ENFoundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, Logging {

    var window: UIWindow?

    private var appRoot: ENAppRoot?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Note: The following needs to be set before application:didFinishLaunchingWithOptions: returns
        let unc = UNUserNotificationCenter.current()
        unc.delegate = self

        logDebug("AppDelegate - application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) Called")

        sendAppLaunchNotification()

        if #available(iOS 13.5, *) {
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "nl.rijksoverheid.en"

            [
                ".exposure-notification",
                ".background-decoy-stop-keys",
                ".background-decoy-sequence",
                ".background-decoy-register"
            ]
            .forEach { identifier in
                BGTaskScheduler.shared.register(forTaskWithIdentifier: bundleIdentifier + identifier, using: .main) { task in
                    self.handle(backgroundTask: task)
                }
            }
        }

        if #available(iOS 13, *) {

        } else {

            logDebug("AppDelegate - Following iOS 12 path")

            let window = UIWindow(frame: UIScreen.main.bounds)
            self.window = window

            appRoot = ENAppRoot()
            appRoot?.attach(toWindow: window)
            window.makeKeyAndVisible()
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Start first flow
        appRoot?.start()
        appRoot?.didBecomeActive()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // notify bridge app entered foreground
        appRoot?.didEnterForeground()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // notify bridge app entered background
        appRoot?.didEnterBackground()
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

    func setAppRoot(appRoot: ENAppRoot?) {
        self.appRoot = appRoot
    }

    // MARK: - Private

    @available(iOS 13.5, *)
    private func handle(backgroundTask: BGTask) {
        guard let appRoot = appRoot else {
            return print("🔥 ENCoreBridge is `nil`")
        }

        appRoot.handle(backgroundTask: backgroundTask)
    }

    private func sendAppLaunchNotification() {

        let unc = UNUserNotificationCenter.current()

        unc.getNotificationSettings { status in
            guard status.authorizationStatus == .authorized else {
                return self.logError("Not authorized to post notifications")
            }

            let formatter = DateFormatter()
            formatter.timeStyle = .long
            let date = formatter.string(from: Date())

            let content = UNMutableNotificationContent()
            content.title = "App Launch notification"
            content.body = "Launched at \(date)"
            content.sound = UNNotificationSound.default
            content.badge = 0

            let identifier = "app-lauch-notification"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

            unc.add(request) { error in
                guard let error = error else {
                    return
                }
                self.logError("Error posting notification: app-lauch-notification \(error.localizedDescription)")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> ()) {

        appRoot?.receiveForegroundNotification(notification)
        completionHandler(.alert)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> ()) {
        appRoot?.receiveRemoteNotification(response: response)
        completionHandler()
    }
}

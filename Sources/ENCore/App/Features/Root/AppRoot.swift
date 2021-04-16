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
import Foundation
import UIKit

@available(iOS 12.5,*)
@objc public final class AppRoot: NSObject, Logging {
    private static var version: String {
        let dictionary = Bundle.main.infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String ?? "n/a"
        let build = dictionary?["CFBundleVersion"] as? String ?? "n/a"
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "n/a"

        return "OS: \(UIDevice.current.systemVersion) App: \(version)-(\(build)) Bundle Identifier: \(bundleIdentifier)"
    }

    private let rootBuilder: RootBuildable
    private var appEntryPoint: AppEntryPoint?

    // Optional RootBuildable gives us the possibility to inject a mock for unit testing
    public init(rootBuilder: RootBuildable? = nil) {
        self.rootBuilder = rootBuilder ?? RootBuilder()
    }
    
    @objc
    public func attach(toWindow window: UIWindow) {
        logDebug("`attach` \(AppRoot.version)")
        guard appEntryPoint == nil else {
            logDebug("AppRoot - appEntryPoint already attached")
            return
        }

        let appEntryPoint = rootBuilder.build()
        self.appEntryPoint = appEntryPoint

        window.rootViewController = appEntryPoint.uiviewController
    }

    @objc
    public func start() {
        logDebug("`start` \(AppRoot.version)")
        guard let appEntryPoint = appEntryPoint else {
            logError("AppRoot - start - appEntryPoint not initialized")
            return
        }
        appEntryPoint.start()
    }

    @objc
    public func receiveRemoteNotification(response: NotificationResponse) {
        logDebug("`receiveRemoteNotification` \(AppRoot.version)")

        guard let identifier = PushNotificationIdentifier(rawValue: response.notificationRequestIdentifier) else {
            return logError("Push notification for \(response.notificationRequestIdentifier) not handled")
        }

        appEntryPoint?.mutablePushNotificationStream.update(identifier: identifier)
    }

    @objc
    public func receiveForegroundNotification(_ notification: UserNotification) {
        logDebug("`receiveRemoteNotificationInForeground` \(AppRoot.version)")
        appEntryPoint?.mutablePushNotificationStream.update(notification: notification)
    }

    @objc
    public func didBecomeActive() {
        logDebug("`didBecomeActive` \(AppRoot.version)")
        guard let appEntryPoint = appEntryPoint else {
            logError("AppRoot - didBecomeActive - appEntryPoint not initialized")
            return
        }
        appEntryPoint.didBecomeActive()
    }

    @objc
    public func didEnterForeground() {
        logDebug("`didEnterForeground` \(AppRoot.version)")
        guard let appEntryPoint = appEntryPoint else {
            logError("AppRoot - didEnterForeground - appEntryPoint not initialized")
            return
        }
        appEntryPoint.didEnterForeground()
    }

    @objc
    public func didEnterBackground() {
        logDebug("`didEnterBackground` \(AppRoot.version)")
        guard let appEntryPoint = appEntryPoint else {
            logError("AppRoot - didEnterBackground - appEntryPoint not initialized")
            return
        }
        appEntryPoint.didEnterBackground()
    }

    @objc
    @available(iOS 13.5,*)
    public func handle(backgroundTask: BackgroundTask) {
        logDebug("`handle` \(AppRoot.version)")
        appEntryPoint?.handle(backgroundTask: backgroundTask)
    }
}

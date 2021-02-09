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
@objc public final class ENAppRoot: NSObject, Logging {
    private static var version: String {
        let dictionary = Bundle.main.infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String ?? "n/a"
        let build = dictionary?["CFBundleVersion"] as? String ?? "n/a"
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "n/a"

        return "OS: \(UIDevice.current.systemVersion) App: \(version)-(\(build)) Bundle Identifier: \(bundleIdentifier)"
    }

    private let rootBuilder = RootBuilder()
    private var appEntryPoint: AppEntryPoint?

    @objc
    public func attach(toWindow window: UIWindow) {
        logDebug("`attach` \(ENAppRoot.version)")
        guard appEntryPoint == nil else {
            logDebug("ENAppRoot - appEntryPoint already attached")
            return
        }

        let appEntryPoint = rootBuilder.build()
        self.appEntryPoint = appEntryPoint

        window.rootViewController = appEntryPoint.uiviewController
    }

    @objc
    public func start() {
        logDebug("`start` \(ENAppRoot.version)")
        guard let appEntryPoint = appEntryPoint else {
            logError("ENAppRoot - start - appEntryPoint not initialized")
            return
        }
        appEntryPoint.start()
    }

    @objc
    public func receiveRemoteNotification(response: UNNotificationResponse) {
        logDebug("`receiveRemoteNotification` \(ENAppRoot.version)")

        guard let identifier = PushNotificationIdentifier(rawValue: response.notification.request.identifier) else {
            return logError("Push notification for \(response.notification.request.identifier) not handled")
        }

        appEntryPoint?.mutablePushNotificationStream.update(identifier: identifier)
    }

    @objc
    public func receiveForegroundNotification(_ notification: UNNotification) {
        logDebug("`receiveRemoteNotificationInForeground` \(ENAppRoot.version)")
        appEntryPoint?.mutablePushNotificationStream.update(notification: notification)
    }

    @objc
    public func didBecomeActive() {
        logDebug("`didBecomeActive` \(ENAppRoot.version)")
        guard let appEntryPoint = appEntryPoint else {
            logError("ENAppRoot - didBecomeActive - appEntryPoint not initialized")
            return
        }
        appEntryPoint.didBecomeActive()
    }

    @objc
    public func didEnterForeground() {
        logDebug("`didEnterForeground` \(ENAppRoot.version)")
        guard let appEntryPoint = appEntryPoint else {
            logError("ENAppRoot - didEnterForeground - appEntryPoint not initialized")
            return
        }
        appEntryPoint.didEnterForeground()
    }

    @objc
    public func didEnterBackground() {
        logDebug("`didEnterBackground` \(ENAppRoot.version)")
        guard let appEntryPoint = appEntryPoint else {
            logError("ENAppRoot - didEnterBackground - appEntryPoint not initialized")
            return
        }
        appEntryPoint.didEnterBackground()
    }

    @objc
    @available(iOS 13.5,*)
    public func handle(backgroundTask: BGTask) {
        logDebug("`handle` \(ENAppRoot.version)")
        appEntryPoint?.handle(backgroundTask: backgroundTask)
    }
}

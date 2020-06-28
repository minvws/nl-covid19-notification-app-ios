/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Foundation
import UIKit

@available(iOS 13.5,*)
@objc public final class ENAppRoot: NSObject {
    private let rootBuilder = RootBuilder()
    private var appEntryPoint: AppEntryPoint?

    @objc
    public func attach(toWindow window: UIWindow) {
        guard appEntryPoint == nil else {
            return
        }

        let appEntryPoint = rootBuilder.build()
        self.appEntryPoint = appEntryPoint

        window.rootViewController = appEntryPoint.uiviewController
    }

    @objc
    public func start() {
        appEntryPoint?.start()
    }

    @objc
    public func receiveRemoteNotification(response: UNNotificationResponse) {
        appEntryPoint?.mutablePushNotificationStream.update(response: response)
    }

    @objc
    public func didEnterForeground() {
        appEntryPoint?.didEnterForeground()
    }

    @objc
    public func didEnterBackground() {
        appEntryPoint?.didEnterBackground()
    }

    @objc
    public func handle(backgroundTask: BGTask) {
        appEntryPoint?.handle(backgroundTask: backgroundTask)
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol ReceivedNotificationListener: AnyObject {
    func receivedNotificationWantsDismissal(shouldDismissViewController: Bool)
    func receivedNotificationRequestRedirect(to content: LinkedContent)
    func receivedNotificationActionButtonTapped()
}

/// @mockable
protocol ReceivedNotificationBuildable {
    /// Builds ReceivedNotification
    ///
    /// - Parameter listener: Listener of created ReceivedNotificationViewController
    /// - Parameter linkedContent: Linked content to be displayed
    /// - Parameter actionButtonTitle: Title for the action button. If nil is set no button will be shown.
    func build(withListener listener: ReceivedNotificationListener, linkedContent: [LinkedContent], actionButtonTitle: String?) -> ViewControllable
}

protocol ReceivedNotificationDependency {
    var theme: Theme { get }
    var deviceOrientationStream: DeviceOrientationStreaming { get }
}

private final class ReceivedNotificationDependencyProvider: DependencyProvider<ReceivedNotificationDependency> {}

final class ReceivedNotificationBuilder: Builder<ReceivedNotificationDependency>, ReceivedNotificationBuildable {
    func build(withListener listener: ReceivedNotificationListener, linkedContent: [LinkedContent], actionButtonTitle: String?) -> ViewControllable {
        let dependencyProvider = ReceivedNotificationDependencyProvider(dependency: dependency)
        return ReceivedNotificationViewController(listener: listener,
                                                  linkedContent: linkedContent,
                                                  actionButtonTitle: actionButtonTitle,
                                                  theme: dependencyProvider.dependency.theme,
                                                  deviceOrientationStream: dependencyProvider.dependency.deviceOrientationStream)
    }
}

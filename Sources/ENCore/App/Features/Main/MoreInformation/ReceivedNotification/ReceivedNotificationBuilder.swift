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
}

/// @mockable
protocol ReceivedNotificationBuildable {
    /// Builds ReceivedNotification
    ///
    /// - Parameter listener: Listener of created ReceivedNotificationViewController
    /// - Parameter linkedContent: Linked content to be displayed
    func build(withListener listener: ReceivedNotificationListener, linkedContent: [LinkedContent]) -> ViewControllable
}

protocol ReceivedNotificationDependency {
    var theme: Theme { get }
}

private final class ReceivedNotificationDependencyProvider: DependencyProvider<ReceivedNotificationDependency> {}

final class ReceivedNotificationBuilder: Builder<ReceivedNotificationDependency>, ReceivedNotificationBuildable {
    func build(withListener listener: ReceivedNotificationListener, linkedContent: [LinkedContent]) -> ViewControllable {
        let dependencyProvider = ReceivedNotificationDependencyProvider(dependency: dependency)
        return ReceivedNotificationViewController(listener: listener,
                                                  linkedContent: linkedContent,
                                                  theme: dependencyProvider.dependency.theme)
    }
}

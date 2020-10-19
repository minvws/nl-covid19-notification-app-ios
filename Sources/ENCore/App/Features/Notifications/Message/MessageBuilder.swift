/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol MessageListener: AnyObject {
    func messageWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol MessageBuildable {
    /// Builds Message
    ///
    /// - Parameter listener: Listener of created MessageViewController
    func build(withListener listener: MessageListener, exposureDate: Date) -> ViewControllable
}

protocol MessageDependency {
    var theme: Theme { get }
    var messageManager: MessageManaging { get }
}

private final class MessageDependencyProvider: DependencyProvider<MessageDependency> {

    var messageManager: MessageManaging {
        return dependency.messageManager
    }
}

final class MessageBuilder: Builder<MessageDependency>, MessageBuildable {
    func build(withListener listener: MessageListener, exposureDate: Date) -> ViewControllable {
        let dependencyProvider = MessageDependencyProvider(dependency: dependency)
        return MessageViewController(listener: listener,
                                     theme: dependencyProvider.dependency.theme,
                                     exposureDate: exposureDate,
                                     messageManager: dependencyProvider.dependency.messageManager)
    }
}

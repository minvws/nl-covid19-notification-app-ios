/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol CallGGDListener: AnyObject {
    func callGGDWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol CallGGDBuildable {
    /// Builds CallGGD
    ///
    /// - Parameter listener: Listener of created CallGGDViewController
    func build(withListener listener: CallGGDListener) -> ViewControllable
}

protocol CallGGDDependency {
    var theme: Theme { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class CallGGDDependencyProvider: DependencyProvider<CallGGDDependency> {}

final class CallGGDBuilder: Builder<CallGGDDependency>, CallGGDBuildable {
    func build(withListener listener: CallGGDListener) -> ViewControllable {
        let dependencyProvider = CallGGDDependencyProvider(dependency: dependency)

        return CallGGDViewController(listener: listener,
                                     theme: dependencyProvider.dependency.theme,
                                     interfaceOrientationStream: dependencyProvider.dependency.interfaceOrientationStream)
    }
}

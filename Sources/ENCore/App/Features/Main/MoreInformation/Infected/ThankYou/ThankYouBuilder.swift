/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol ThankYouListener: AnyObject {
    func thankYouWantsDismissal()
}

/// @mockable
protocol ThankYouBuildable {
    /// Builds ThankYou
    ///
    /// - Parameter listener: Listener of created ThankYouViewController
    func build(withListener listener: ThankYouListener) -> ViewControllable
}

protocol ThankYouDependency {
    var theme: Theme { get }
}

private final class ThankYouDependencyProvider: DependencyProvider<ThankYouDependency> {}

final class ThankYouBuilder: Builder<ThankYouDependency>, ThankYouBuildable {
    func build(withListener listener: ThankYouListener) -> ViewControllable {
        let dependencyProvider = ThankYouDependencyProvider(dependency: dependency)
        return ThankYouViewController(listener: listener,
                                      theme: dependencyProvider.dependency.theme)
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol NoInternetListener: AnyObject {
    func noInternetRequestsRetry()
}

/// @mockable
protocol NoInternetBuildable {
    /// Builds NoInternet
    ///
    /// - Parameter listener: Listener of created NoInternetViewController
    func build(withListener listener: NoInternetListener) -> ViewControllable
}

protocol NoInternetDependency {
    var theme: Theme { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class NoInternetDependencyProvider: DependencyProvider<NoInternetDependency> {}

final class NoInternetBuilder: Builder<NoInternetDependency>, NoInternetBuildable {
    func build(withListener listener: NoInternetListener) -> ViewControllable {
        let dependencyProvider = NoInternetDependencyProvider(dependency: dependency)
        return NoInternetViewController(listener: listener, theme: dependencyProvider.dependency.theme, interfaceOrientationStream: dependencyProvider.dependency.interfaceOrientationStream)
    }
}

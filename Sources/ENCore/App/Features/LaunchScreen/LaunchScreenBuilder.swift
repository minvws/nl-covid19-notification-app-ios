/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol LaunchScreenBuildable {
    func build() -> ViewControllable
}

protocol LaunchScreenDependency {
    var theme: Theme { get }
}

private final class LaunchScreenDependencyProvider: DependencyProvider<LaunchScreenDependency> {

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }
}

final class LaunchScreenBuilder: Builder<LaunchScreenDependency>, LaunchScreenBuildable {

    func build() -> ViewControllable {
        let dependencyProvider = LaunchScreenDependencyProvider(dependency: dependency)
        return LaunchScreenViewController(theme: dependencyProvider.dependency.theme)
    }
}

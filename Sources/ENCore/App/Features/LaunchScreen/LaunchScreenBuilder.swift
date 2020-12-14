/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

protocol LaunchScreenBuildable {
    func build() -> Routing
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

    func build() -> Routing {
        let dependencyProvider = LaunchScreenDependencyProvider(dependency: dependency)
        let viewController = LaunchScreenViewController(theme: dependencyProvider.dependency.theme)

        return LaunchScreenRouter(viewController: viewController)
    }
}

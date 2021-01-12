/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol UpdateOperatingSystemBuildable {
    func build() -> Routing
}

protocol UpdateOperatingSystemDependency {
    var theme: Theme { get }
}

private final class UpdateOperatingSystemDependencyProvider: DependencyProvider<UpdateOperatingSystemDependency> {

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }
}

final class UpdateOperatingSystemBuilder: Builder<UpdateOperatingSystemDependency>, UpdateOperatingSystemBuildable {

    func build() -> Routing {
        let dependencyProvider = UpdateOperatingSystemDependencyProvider(dependency: dependency)
        let viewController = UpdateOperatingSystemViewController(theme: dependencyProvider.dependency.theme)

        return UpdateOperatingSystemRouter(viewController: viewController)
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol DashboardListener: AnyObject {
    func dashboardRequestsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol DashboardBuildable {
    func build(withListener listener: DashboardListener,
               identifier: DashboardIdentifier) -> Routing
}

protocol DashboardDependency {
    var theme: Theme { get }
    // TODO: Add any external dependency
}

private final class DashboardDependencyProvider: DependencyProvider<DashboardDependency>, DashboardOverviewDependency /* , ChildDependency */ {

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    // MARK: - Child Builders

    var overviewBuilder: DashboardOverviewBuildable {
        return DashboardOverviewBuilder(dependency: self)
    }
}

final class DashboardBuilder: Builder<DashboardDependency>, DashboardBuildable {
    func build(withListener listener: DashboardListener,
               identifier: DashboardIdentifier) -> Routing {
        // TODO: Add any other dynamic dependency as parameter

        let dependencyProvider = DashboardDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = DashboardViewController(listener: listener,
                                                     theme: dependencyProvider.dependency.theme,
                                                     identifier: identifier)

        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return DashboardRouter(viewController: viewController,
                               overviewBuilder: dependencyProvider.overviewBuilder)
    }
}

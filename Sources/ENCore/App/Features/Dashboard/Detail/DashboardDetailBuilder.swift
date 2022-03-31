/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol DashboardDetailListener: AnyObject {
    func dashboardDetailRequestsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol DashboardDetailBuildable {
    func build(withListener listener: DashboardDetailListener,
               identifier: DashboardIdentifier) -> Routing
}

protocol DashboardDetailDependency {
    var theme: Theme { get }
    // TODO: Add any external dependency
}

private final class DashboardDetailDependencyProvider: DependencyProvider<DashboardDetailDependency>, DashboardOverviewDependency /* , ChildDependency */ {

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    // MARK: - Child Builders

    var overviewBuilder: DashboardOverviewBuildable {
        return DashboardOverviewBuilder(dependency: self)
    }
}

final class DashboardDetailBuilder: Builder<DashboardDetailDependency>, DashboardDetailBuildable {
    func build(withListener listener: DashboardDetailListener,
               identifier: DashboardIdentifier) -> Routing {
        // TODO: Add any other dynamic dependency as parameter

        let dependencyProvider = DashboardDetailDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = DashboardDetailViewController(listener: listener,
                                                           theme: dependencyProvider.dependency.theme,
                                                           identifier: identifier)

        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return DashboardDetailRouter(viewController: viewController,
                                     overviewBuilder: dependencyProvider.overviewBuilder)
    }
}

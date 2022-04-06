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
    var dataController: ExposureDataControlling { get }
}

private final class DashboardDependencyProvider: DependencyProvider<DashboardDependency>, DashboardOverviewDependency, DashboardDetailDependency {

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    var dataController: ExposureDataControlling {
        return dependency.dataController
    }

    // MARK: - Child Builders

    var overviewBuilder: DashboardOverviewBuildable {
        return DashboardOverviewBuilder(dependency: self)
    }

    var detailBuilder: DashboardDetailBuildable {
        return DashboardDetailBuilder(dependency: self)
    }
}

final class DashboardBuilder: Builder<DashboardDependency>, DashboardBuildable {
    func build(withListener listener: DashboardListener,
               identifier: DashboardIdentifier) -> Routing {
        let dependencyProvider = DashboardDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = DashboardViewController(listener: listener,
                                                     theme: dependencyProvider.dependency.theme,
                                                     identifier: identifier,
                                                     dataController: dependencyProvider.dataController)

        return DashboardRouter(viewController: viewController,
                               overviewBuilder: dependencyProvider.overviewBuilder,
                               detailBuilder: dependencyProvider.detailBuilder)
    }
}

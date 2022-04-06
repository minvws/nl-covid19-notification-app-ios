/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol DashboardSummaryListener: AnyObject {
    func dashboardSummaryRequestsRouteToDetail(with identifier: DashboardIdentifier)
}

/// @mockable
protocol DashboardSummaryBuildable {
    /// Builds Dashboard
    ///
    /// - Parameter listener: Listener of created Dashboard component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: DashboardSummaryListener) -> ViewControllable
}

protocol DashboardSummaryDependency {
    var theme: Theme { get }
    var dataController: ExposureDataControlling { get }
}

private final class DashboardSummaryDependencyProvider: DependencyProvider<DashboardSummaryDependency> /* , ChildDependency */ {
    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    var dataController: ExposureDataControlling {
        return dependency.dataController
    }
}

final class DashboardSummaryBuilder: Builder<DashboardSummaryDependency>, DashboardSummaryBuildable {
    func build(withListener listener: DashboardSummaryListener) -> ViewControllable {

        let dependencyProvider = DashboardSummaryDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = DashboardSummaryViewController(listener: listener,
                                                            theme: dependencyProvider.theme,
                                                            dataController: dependencyProvider.dataController)
        return viewController
    }
}

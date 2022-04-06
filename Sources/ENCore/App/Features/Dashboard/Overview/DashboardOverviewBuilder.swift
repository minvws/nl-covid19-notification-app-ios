/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol DashboardOverviewListener: AnyObject {
    func dashboardOverviewRequestsRouteToDetail(with identifier: DashboardIdentifier)
}

/// @mockable
protocol DashboardOverviewBuildable {
    func build(withData data: DashboardData, listener: DashboardOverviewListener) -> ViewControllable
}

protocol DashboardOverviewDependency {
    var theme: Theme { get }
}

private final class DashboardOverviewDependencyProvider: DependencyProvider<DashboardOverviewDependency> {}

final class DashboardOverviewBuilder: Builder<DashboardOverviewDependency>, DashboardOverviewBuildable {
    func build(withData data: DashboardData, listener: DashboardOverviewListener) -> ViewControllable {
        let dependencyProvider = DashboardOverviewDependencyProvider(dependency: dependency)

        return DashboardOverviewViewController(listener: listener, data: data, theme: dependencyProvider.dependency.theme)
    }
}

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
    func dashboardDetailRequestsRouteToDetail(with identifier: DashboardIdentifier)
}

/// @mockable
protocol DashboardDetailBuildable {
    func build(withData data: DashboardData, listener: DashboardDetailListener, identifier: DashboardIdentifier) -> ViewControllable
}

protocol DashboardDetailDependency {
    var theme: Theme { get }
}

private final class DashboardDetailDependencyProvider: DependencyProvider<DashboardDetailDependency> {}

final class DashboardDetailBuilder: Builder<DashboardDetailDependency>, DashboardDetailBuildable {
    func build(withData data: DashboardData, listener: DashboardDetailListener, identifier: DashboardIdentifier) -> ViewControllable {
        let dependencyProvider = DashboardDetailDependencyProvider(dependency: dependency)

        return DashboardDetailViewController(listener: listener, data: data, identifier: identifier, theme: dependencyProvider.dependency.theme)
    }
}

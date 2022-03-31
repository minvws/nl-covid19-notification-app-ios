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
    func build(withListener listener: DashboardDetailListener, identifier: DashboardIdentifier) -> ViewControllable
}

protocol DashboardDetailDependency {
    var theme: Theme { get }
    // TODO: Add any external dependency
}

private final class DashboardDetailDependencyProvider: DependencyProvider<DashboardDetailDependency> /* , ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to DashboardDetail's scope or any child of DashboardDetail

    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    // }
}

final class DashboardDetailBuilder: Builder<DashboardDetailDependency>, DashboardDetailBuildable {
    func build(withListener listener: DashboardDetailListener, identifier: DashboardIdentifier) -> ViewControllable {
        let dependencyProvider = DashboardDetailDependencyProvider(dependency: dependency)

        return DashboardDetailViewController(listener: listener, identifier: identifier, theme: dependencyProvider.dependency.theme)
    }
}

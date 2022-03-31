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
    func dashboardRequestsRouteToDetail(with identifier: DashboardIdentifier)
    func dashboardRequestsRouteToOverview()
}

/// @mockable
protocol DashboardBuildable {
    /// Builds Dashboard
    ///
    /// - Parameter listener: Listener of created Dashboard component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: DashboardListener) -> ViewControllable
}

protocol DashboardDependency {
    var theme: Theme { get }
    // TODO: Add any external dependency
}

private final class DashboardDependencyProvider: DependencyProvider<DashboardDependency> /* , ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to Dashboard's scope or any child of Dashboard

    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    // }
}

final class DashboardBuilder: Builder<DashboardDependency>, DashboardBuildable {
    func build(withListener listener: DashboardListener) -> ViewControllable {
        // TODO: Add any other dynamic dependency as parameter

        let dependencyProvider = DashboardDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = DashboardViewController(listener: listener, theme: dependencyProvider.dependency.theme)

        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return viewController
    }
}

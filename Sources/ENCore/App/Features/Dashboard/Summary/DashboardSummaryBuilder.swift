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
    func dashboardSummaryRequestsRouteToOverview()
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
    // TODO: Add any external dependency
}

private final class DashboardSummaryDependencyProvider: DependencyProvider<DashboardSummaryDependency> /* , ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to Dashboard's scope or any child of Dashboard

    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    // }
}

final class DashboardBuilder: Builder<DashboardSummaryDependency>, DashboardSummaryBuildable {
    func build(withListener listener: DashboardSummaryListener) -> ViewControllable {
        // TODO: Add any other dynamic dependency as parameter

        let dependencyProvider = DashboardSummaryDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = DashboardSummaryViewController(listener: listener, theme: dependencyProvider.dependency.theme)

        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return viewController
    }
}

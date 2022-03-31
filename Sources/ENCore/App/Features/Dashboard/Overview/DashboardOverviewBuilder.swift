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
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol DashboardOverviewBuildable {
    func build(withListener listener: DashboardOverviewListener) -> ViewControllable
}

protocol DashboardOverviewDependency {
    var theme: Theme { get }
    // TODO: Add any external dependency
}

private final class DashboardOverviewDependencyProvider: DependencyProvider<DashboardOverviewDependency> /* , ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to DashboardOverview's scope or any child of DashboardOverview

    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    // }
}

final class DashboardOverviewBuilder: Builder<DashboardOverviewDependency>, DashboardOverviewBuildable {
    func build(withListener listener: DashboardOverviewListener) -> ViewControllable {
        let dependencyProvider = DashboardOverviewDependencyProvider(dependency: dependency)

        return DashboardOverviewViewController(listener: listener, theme: dependencyProvider.dependency.theme)
    }
}

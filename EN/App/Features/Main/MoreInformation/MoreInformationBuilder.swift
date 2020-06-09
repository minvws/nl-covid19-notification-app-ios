/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol MoreInformationListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol MoreInformationBuildable {
    /// Builds MoreInformation
    ///
    /// - Parameter listener: Listener of created MoreInformation component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: MoreInformationListener) -> Routing
}

protocol MoreInformationDependency {
    // TODO: Add any external dependency
}

private final class MoreInformationDependencyProvider: DependencyProvider<MoreInformationDependency> /*, ChildDependency */ {
    var tableController: MoreInformationTableControlling {
        return MoreInformationTableController()
    }
}

final class MoreInformationBuilder: Builder<MoreInformationDependency>, MoreInformationBuildable {
    func build(withListener listener: MoreInformationListener) -> Routing {
        let dependencyProvider = MoreInformationDependencyProvider(dependency: dependency)
        
        let tableController = dependencyProvider.tableController
        let viewController = MoreInformationViewController(tableController: tableController)
        
        
        return MoreInformationRouter(listener: listener,
                                     viewController: viewController)
    }
}

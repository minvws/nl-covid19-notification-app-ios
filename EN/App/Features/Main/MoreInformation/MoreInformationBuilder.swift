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
    // TODO: Create and return any dependency that should be limited
    //       to MoreInformation's scope or any child of MoreInformation
    
    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    //}
}

final class MoreInformationBuilder: Builder<MoreInformationDependency>, MoreInformationBuildable {
    func build(withListener listener: MoreInformationListener) -> Routing {
        // TODO: Add any other dynamic dependency as parameter
        
        let dependencyProvider = MoreInformationDependencyProvider(dependency: dependency)
        
        // let childBuilder = dependencyProvider.childBuilder
        let viewController = MoreInformationViewController()
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return MoreInformationRouter(listener: listener,
                                                  viewController: viewController /*,
                                                  childBuilder: childBuilder */)
    }
}

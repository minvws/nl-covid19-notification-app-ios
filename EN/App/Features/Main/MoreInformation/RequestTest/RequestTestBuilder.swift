/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol RequestTestListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol RequestTestBuildable {
    /// Builds RequestTest
    ///
    /// - Parameter listener: Listener of created RequestTest component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: RequestTestListener) -> Routing
}

protocol RequestTestDependency {
    // TODO: Add any external dependency
}

private final class RequestTestDependencyProvider: DependencyProvider<RequestTestDependency> /*, ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to RequestTest's scope or any child of RequestTest
    
    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    //}
}

final class RequestTestBuilder: Builder<RequestTestDependency>, RequestTestBuildable {
    func build(withListener listener: RequestTestListener) -> Routing {
        // TODO: Add any other dynamic dependency as parameter
        
        let dependencyProvider = RequestTestDependencyProvider(dependency: dependency)
        
        // let childBuilder = dependencyProvider.childBuilder
        let viewController = RequestTestViewController()
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return RequestTestRouter(listener: listener,
                                                  viewController: viewController /*,
                                                  childBuilder: childBuilder */)
    }
}

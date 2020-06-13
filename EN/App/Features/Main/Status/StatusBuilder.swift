/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol StatusListener: AnyObject {
    func handleButtonAction(_ action: StatusViewButtonModel.Action)
}

/// @mockable
protocol StatusBuildable {
    /// Builds Status
    ///
    /// - Parameter listener: Listener of created Status component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: StatusListener) -> StatusRouting
}

protocol StatusDependency {
    var exposureStateStream: ExposureStateStreaming { get }
}

private final class StatusDependencyProvider: DependencyProvider<StatusDependency> /*, ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to Status's scope or any child of Status
    
    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    //}
}

final class StatusBuilder: Builder<StatusDependency>, StatusBuildable {
    func build(withListener listener: StatusListener) -> StatusRouting {
        // TODO: Add any other dynamic dependency as parameter
        
        // let childBuilder = dependencyProvider.childBuilder
        let viewController = StatusViewController(
            exposureStateStream: dependency.exposureStateStream,
            listener: listener
        )
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return StatusRouter(listener: listener,
                                                  viewController: viewController /*,
                                                  childBuilder: childBuilder */)
    }
}

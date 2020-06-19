/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol InfectedInfoListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol InfectedInfoBuildable {
    /// Builds InfectedInfo
    ///
    /// - Parameter listener: Listener of created InfectedInfo component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: InfectedInfoListener) -> Routing
}

protocol InfectedInfoDependency {
    // TODO: Add any external dependency
    var theme: Theme { get }
}

private final class InfectedInfoDependencyProvider: DependencyProvider<InfectedInfoDependency> /* , ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to InfectedInfo's scope or any child of InfectedInfo

    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    // }
}

final class InfectedInfoBuilder: Builder<InfectedInfoDependency>, InfectedInfoBuildable {
    func build(withListener listener: InfectedInfoListener) -> Routing {
        // TODO: Add any other dynamic dependency as parameter

        let dependencyProvider = InfectedInfoDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = InfectedInfoViewController(theme: dependencyProvider.dependency.theme)

        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return InfectedInfoRouter(listener: listener,
                                  viewController: viewController /* ,
                                   childBuilder: childBuilder */ )
    }
}

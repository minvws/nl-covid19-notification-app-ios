/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol InfectedListener: AnyObject {
    func infectedWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol InfectedBuildable {
    /// Builds Infected
    ///
    /// - Parameter listener: Listener of created Infected component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: InfectedListener) -> Routing
}

protocol InfectedDependency {
    var theme: Theme { get }
}

private final class InfectedDependencyProvider: DependencyProvider<InfectedDependency> /* , ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to Infected's scope or any child of Infected

    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    // }
}

final class InfectedBuilder: Builder<InfectedDependency>, InfectedBuildable {
    func build(withListener listener: InfectedListener) -> Routing {
        // TODO: Add any other dynamic dependency as parameter

        let dependencyProvider = InfectedDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = InfectedViewController(theme: dependencyProvider.dependency.theme)

        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return InfectedRouter(listener: listener,
                              viewController: viewController /* ,
                               childBuilder: childBuilder */ )
    }
}

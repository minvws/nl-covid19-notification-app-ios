/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol PauseConfirmationListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol PauseConfirmationBuildable {
    /// Builds PauseConfirmation
    ///
    /// - Parameter listener: Listener of created PauseConfirmation component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: PauseConfirmationListener) -> Routing
}

protocol PauseConfirmationDependency {
    var theme: Theme { get }
    // TODO: Add any external dependency
}

private final class PauseConfirmationDependencyProvider: DependencyProvider<PauseConfirmationDependency> /* , ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to PauseConfirmation's scope or any child of PauseConfirmation

    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    // }
}

final class PauseConfirmationBuilder: Builder<PauseConfirmationDependency>, PauseConfirmationBuildable {
    func build(withListener listener: PauseConfirmationListener) -> Routing {
        // TODO: Add any other dynamic dependency as parameter

        let dependencyProvider = PauseConfirmationDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = PauseConfirmationViewController(theme: dependencyProvider.dependency.theme)

        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return PauseConfirmationRouter(listener: listener,
                                       viewController: viewController /* ,
                                        childBuilder: childBuilder */ )
    }
}

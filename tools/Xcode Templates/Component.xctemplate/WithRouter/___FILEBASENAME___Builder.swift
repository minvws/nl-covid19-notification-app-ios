/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol ___VARIABLE_componentName___Listener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol ___VARIABLE_componentName___Buildable {
    /// Builds ___VARIABLE_componentName___
    ///
    /// - Parameter listener: Listener of created ___VARIABLE_componentName___ component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: ___VARIABLE_componentName___Listener) -> Routing
}

protocol ___VARIABLE_componentName___Dependency {
    // TODO: Add any external dependency
}

private final class ___VARIABLE_componentName___DependencyProvider: DependencyProvider<___VARIABLE_componentName___Dependency> /* , ChildDependency */ {
    // TODO: Create and return any dependency that should be limited
    //       to ___VARIABLE_componentName___'s scope or any child of ___VARIABLE_componentName___

    // TODO: Replace `childBuilder` by a real child scope and adjust
    //       `ChildDependency`
    // var childBuilder: ChildBuildable {
    //    return ChildBuilder(dependency: self)
    // }
}

final class ___VARIABLE_componentName___Builder: Builder<___VARIABLE_componentName___Dependency>, ___VARIABLE_componentName___Buildable {
    func build(withListener listener: ___VARIABLE_componentName___Listener) -> Routing {
        // TODO: Add any other dynamic dependency as parameter

        let dependencyProvider = ___VARIABLE_componentName___DependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = ___VARIABLE_componentName___ViewController()

        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return ___VARIABLE_componentName___Router(listener: listener,
                                                  viewController: viewController /* ,
                                                   childBuilder: childBuilder */ )
    }
}

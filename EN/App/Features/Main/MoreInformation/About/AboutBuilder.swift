/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol AboutListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol AboutBuildable {
    /// Builds About
    ///
    /// - Parameter listener: Listener of created AboutViewController
    func build(withListener listener: AboutListener) -> ViewControllable
}

protocol AboutDependency {
    // TODO: Add any external dependency
}

private final class AboutDependencyProvider: DependencyProvider<AboutDependency> {
    // TODO: Create and return any dependency that should be limited
    //       to About's scope or any child of About
}

final class AboutBuilder: Builder<AboutDependency>, AboutBuildable {
    func build(withListener listener: AboutListener) -> ViewControllable {
        // TODO: Add any other dynamic dependency as parameter
        
        let dependencyProvider = AboutDependencyProvider(dependency: dependency)
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return AboutViewController(listener: listener)
    }
}

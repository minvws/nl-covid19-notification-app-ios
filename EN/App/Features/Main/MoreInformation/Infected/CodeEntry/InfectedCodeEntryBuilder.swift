/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol InfectedCodeEntryListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol InfectedCodeEntryBuildable {
    /// Builds InfectedCodeEntry
    ///
    /// - Parameter listener: Listener of created InfectedCodeEntryViewController
    func build(withListener listener: InfectedCodeEntryListener) -> ViewControllable
}

protocol InfectedCodeEntryDependency {
    // TODO: Add any external dependency
}

private final class InfectedCodeEntryDependencyProvider: DependencyProvider<InfectedCodeEntryDependency> {
    // TODO: Create and return any dependency that should be limited
    //       to InfectedCodeEntry's scope or any child of InfectedCodeEntry
}

final class InfectedCodeEntryBuilder: Builder<InfectedCodeEntryDependency>, InfectedCodeEntryBuildable {
    func build(withListener listener: InfectedCodeEntryListener) -> ViewControllable {
        // TODO: Add any other dynamic dependency as parameter
        
        let dependencyProvider = InfectedCodeEntryDependencyProvider(dependency: dependency)
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return InfectedCodeEntryViewController(listener: listener)
    }
}

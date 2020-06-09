/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol InfectedResultListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol InfectedResultBuildable {
    /// Builds InfectedResult
    ///
    /// - Parameter listener: Listener of created InfectedResultViewController
    func build(withListener listener: InfectedResultListener) -> ViewControllable
}

protocol InfectedResultDependency {
    // TODO: Add any external dependency
}

private final class InfectedResultDependencyProvider: DependencyProvider<InfectedResultDependency> {
    // TODO: Create and return any dependency that should be limited
    //       to InfectedResult's scope or any child of InfectedResult
}

final class InfectedResultBuilder: Builder<InfectedResultDependency>, InfectedResultBuildable {
    func build(withListener listener: InfectedResultListener) -> ViewControllable {
        // TODO: Add any other dynamic dependency as parameter
        
        let dependencyProvider = InfectedResultDependencyProvider(dependency: dependency)
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return InfectedResultViewController(listener: listener)
    }
}

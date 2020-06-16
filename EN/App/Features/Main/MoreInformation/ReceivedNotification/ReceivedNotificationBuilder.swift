/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol ReceivedNotificationListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol ReceivedNotificationBuildable {
    /// Builds ReceivedNotification
    ///
    /// - Parameter listener: Listener of created ReceivedNotificationViewController
    func build(withListener listener: ReceivedNotificationListener) -> ViewControllable
}

protocol ReceivedNotificationDependency {
    var theme: Theme { get }
}

private final class ReceivedNotificationDependencyProvider: DependencyProvider<ReceivedNotificationDependency> {
    // TODO: Create and return any dependency that should be limited
    //       to ReceivedNotification's scope or any child of ReceivedNotification
}

final class ReceivedNotificationBuilder: Builder<ReceivedNotificationDependency>, ReceivedNotificationBuildable {
    func build(withListener listener: ReceivedNotificationListener) -> ViewControllable {
        // TODO: Add any other dynamic dependency as parameter
        
        let dependencyProvider = ReceivedNotificationDependencyProvider(dependency: dependency)
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return ReceivedNotificationViewController(listener: listener, theme: dependencyProvider.dependency.theme)
    }
}

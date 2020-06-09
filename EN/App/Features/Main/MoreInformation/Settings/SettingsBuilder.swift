/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol SettingsListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol SettingsBuildable {
    /// Builds Settings
    ///
    /// - Parameter listener: Listener of created SettingsViewController
    func build(withListener listener: SettingsListener) -> ViewControllable
}

protocol SettingsDependency {
    // TODO: Add any external dependency
}

private final class SettingsDependencyProvider: DependencyProvider<SettingsDependency> {
    // TODO: Create and return any dependency that should be limited
    //       to Settings's scope or any child of Settings
}

final class SettingsBuilder: Builder<SettingsDependency>, SettingsBuildable {
    func build(withListener listener: SettingsListener) -> ViewControllable {
        // TODO: Add any other dynamic dependency as parameter
        
        let dependencyProvider = SettingsDependencyProvider(dependency: dependency)
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return SettingsViewController(listener: listener)
    }
}

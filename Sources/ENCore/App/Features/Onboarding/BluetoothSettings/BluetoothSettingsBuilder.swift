/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

/// @mockable
protocol BluetoothSettingsListener: AnyObject {
    func bluetoothSettingsDidComplete()
    func isBluetoothEnabled(_ completion: @escaping ((Bool) -> ()))
}

protocol BluetoothSettingsDependency {
    var theme: Theme { get }
}

/// @mockable(history:build=true)
protocol BluetoothSettingsBuildable {
    /// Builds  BluetoothSettingsViewController
    ///
    /// - Parameter listener: Listener of created BluetoothSettingsViewController
    func build(withListener listener: BluetoothSettingsListener) -> ViewControllable
}

private final class BluetoothSettingsDependencyProvider: DependencyProvider<BluetoothSettingsDependency> {}

final class BluetoothSettingsBuilder: Builder<BluetoothSettingsDependency>, BluetoothSettingsBuildable {
    func build(withListener listener: BluetoothSettingsListener) -> ViewControllable {
        let dependencyProvider = BluetoothSettingsDependencyProvider(dependency: dependency)
        return BluetoothSettingsViewController(listener: listener,
                                               theme: dependencyProvider.dependency.theme)
    }
}

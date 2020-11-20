/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol SettingsListener: AnyObject {
    func settingsWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol SettingsBuildable {
    /// Builds RequestTest
    ///
    /// - Parameter listener: Listener of created Settings component
    func build(withListener listener: SettingsListener) -> ViewControllable
}

protocol SettingsDependency {
    var theme: Theme { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class SettingsDependencyProvider: DependencyProvider<SettingsDependency> {}

final class SettingsBuilder: Builder<SettingsDependency>, SettingsBuildable {
    func build(withListener listener: SettingsListener) -> ViewControllable {
        let dependencyProvider = SettingsDependencyProvider(dependency: dependency)
        return SettingsViewController(listener: listener,
                                      theme: dependencyProvider.dependency.theme,
                                      interfaceOrientationStream: dependencyProvider.dependency.interfaceOrientationStream)
    }
}

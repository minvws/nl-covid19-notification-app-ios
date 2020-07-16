/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol EnableSettingListener: AnyObject {
    func enableSettingRequestsDismiss(shouldDismissViewController: Bool)
    func enableSettingDidTriggerAction()
}

protocol EnableSettingDependency {
    var theme: Theme { get }
}

final class EnableSettingDependencyProvider: DependencyProvider<EnableSettingDependency> {
    var theme: Theme {
        return dependency.theme
    }
}

/// @mockable
protocol EnableSettingBuildable {
    /// Builds EnableSettingViewController
    ///
    /// - Parameter listener: Listener of created EnableSettingViewController
    func build(withListener listener: EnableSettingListener,
               setting: EnableSetting) -> ViewControllable
}

final class EnableSettingBuilder: Builder<EnableSettingDependency>, EnableSettingBuildable {
    func build(withListener listener: EnableSettingListener, setting: EnableSetting) -> ViewControllable {
        let dependencyProvider = EnableSettingDependencyProvider(dependency: dependency)

        return EnableSettingViewController(listener: listener,
                                           theme: dependencyProvider.theme,
                                           setting: setting)
    }
}

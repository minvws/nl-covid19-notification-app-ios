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

    /// Builds the settings screen
    /// - Parameter listener: Listener of created Settings component
    func build(withListener listener: SettingsListener) -> Routing
}

protocol SettingsDependency {
    var theme: Theme { get }
    var dataController: ExposureDataControlling { get }
    var pauseController: PauseControlling { get }
}

private final class SettingsDependencyProvider: DependencyProvider<SettingsDependency>, SettingsOverviewDependency, MobileDataDependency, PauseConfirmationDependency {

    var theme: Theme {
        dependency.theme
    }

    var settingsOverviewBuilder: SettingsOverviewBuildable {
        SettingsOverviewBuilder(dependency: self)
    }

    var mobileDataBuilder: MobileDataBuildable {
        MobileDataBuilder(dependency: self)
    }

    var pauseConfirmationBuilder: PauseConfirmationBuildable {
        PauseConfirmationBuilder(dependency: self)
    }

    var exposureDataController: ExposureDataControlling {
        dependency.dataController
    }

    var pauseController: PauseControlling {
        dependency.pauseController
    }
}

final class SettingsBuilder: Builder<SettingsDependency>, SettingsBuildable {
    func build(withListener listener: SettingsListener) -> Routing {
        let dependencyProvider = SettingsDependencyProvider(dependency: dependency)
        let viewController = SettingsViewController(listener: listener, theme: dependencyProvider.dependency.theme)

        return SettingsRouter(viewController: viewController,
                              settingsOverviewBuilder: dependencyProvider.settingsOverviewBuilder,
                              mobileDataBuilder: dependencyProvider.mobileDataBuilder,
                              pauseConfirmationBuilder: dependencyProvider.pauseConfirmationBuilder,
                              exposureDataController: dependencyProvider.exposureDataController)
    }
}

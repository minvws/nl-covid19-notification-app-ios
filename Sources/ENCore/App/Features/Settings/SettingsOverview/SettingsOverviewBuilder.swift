/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol SettingsOverviewListener: AnyObject {
    func settingsOverviewRequestsRoutingToMobileData()
}

/// @mockable
protocol SettingsOverviewBuildable {
    func build(withListener listener: SettingsOverviewListener) -> Routing
}

protocol SettingsOverviewDependency {
    var theme: Theme { get }
    var exposureDataController: ExposureDataControlling { get }
    var pauseController: PauseControlling { get }
    var pauseConfirmationBuilder: PauseConfirmationBuildable { get }
    var pushNotificationStream: PushNotificationStreaming { get }
    var storageController: StorageControlling { get }
}

final class SettingsOverviewDependencyDependencyProvider: DependencyProvider<SettingsOverviewDependency> {}

final class SettingsOverviewBuilder: Builder<SettingsOverviewDependency>, SettingsOverviewBuildable {
    func build(withListener listener: SettingsOverviewListener) -> Routing {
        let dependencyProvider = SettingsOverviewDependencyDependencyProvider(dependency: dependency)
        let viewController = SettingsOverviewViewController(listener: listener,
                                                            theme: dependencyProvider.dependency.theme,
                                                            exposureDataController: dependencyProvider.dependency.exposureDataController,
                                                            pauseController: dependencyProvider.dependency.pauseController,
                                                            pushNotificationStream: dependencyProvider.dependency.pushNotificationStream,
                                                            storageController: dependencyProvider.dependency.storageController)
        return SettingsOverviewRouter(listener: listener,
                                      viewController: viewController,
                                      exposureDataController: dependencyProvider.dependency.exposureDataController,
                                      pauseConfirmationBuilder: dependencyProvider.dependency.pauseConfirmationBuilder)
    }
}

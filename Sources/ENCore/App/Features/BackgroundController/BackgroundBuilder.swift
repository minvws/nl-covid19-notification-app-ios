/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Foundation
import UserNotifications

/// @mockable
protocol BackgroundControlling {
    func scheduleTasks()
    func handle(task: BGTask)
}

protocol BackgroundDependency {
    var exposureManager: ExposureManaging { get }
    var exposureController: ExposureControlling { get }
    var networkController: NetworkControlling { get }
}

/// @mockable
protocol BackgroundControllerBuildable {
    func build() -> BackgroundControlling
}

private final class BackgroundControllerDependencyProvider: DependencyProvider<BackgroundDependency> {

    fileprivate var userNotificationCenter: UserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    fileprivate var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "nl.rijksoverheid.en"
    }
}

final class BackgroundControllerBuilder: Builder<BackgroundDependency>, BackgroundControllerBuildable {
    func build() -> BackgroundControlling {
        let dependencyProvider = BackgroundControllerDependencyProvider(dependency: dependency)
        let configuration = BackgroundTaskConfiguration(decoyProbabilityRange: 0 ..< 1,
                                                        decoyHourRange: 7 ... 18,
                                                        decoyMinuteRange: 0 ... 59,
                                                        decoyDelayRange: 5 ... 900)
        return BackgroundController(exposureController: dependencyProvider.dependency.exposureController,
                                    networkController: dependencyProvider.dependency.networkController,
                                    configuration: configuration,
                                    exposureManager: dependencyProvider.dependency.exposureManager,
                                    userNotificationCenter: dependencyProvider.userNotificationCenter,
                                    bundleIdentifier: dependencyProvider.bundleIdentifier)
    }
}

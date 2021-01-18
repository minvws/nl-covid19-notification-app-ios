/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(BackgroundTasks)
    import BackgroundTasks
#endif

import Foundation
import UserNotifications

/// @mockable
protocol BackgroundControlling {
    func scheduleTasks()
    @available(iOS 13, *)
    func handle(task: BGTask)
    func removeAllTasks()
    func performDecoySequenceIfNeeded()
}

protocol BackgroundDependency {
    var exposureManager: ExposureManaging { get }
    var exposureController: ExposureControlling { get }
    var networkController: NetworkControlling { get }
    var dataController: ExposureDataControlling { get }
    var randomNumberGenerator: RandomNumberGenerating { get }
}

/// @mockable
protocol TaskScheduling {
    @available(iOS 13, *)
    func submit(_ taskRequest: BGTaskRequest) throws
    func cancel(taskRequestWithIdentifier identifier: String)
    func cancelAllTaskRequests()
}

/// Temporary dummy class to pass a TaskScheduling object to BackgroundController
class DummyTaskScheduling: TaskScheduling {
    @available(iOS 13, *)
    func submit(_ taskRequest: BGTaskRequest) throws {}

    func cancel(taskRequestWithIdentifier identifier: String) {}

    func cancelAllTaskRequests() {}
}

@available(iOS 13, *)
extension BGTaskScheduler: TaskScheduling {}

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
                                                        decoyHourRange: 0 ... 23,
                                                        decoyMinuteRange: 0 ... 59,
                                                        decoyDelayRangeLowerBound: 1 ... (24 * 60 * 60),
                                                        decoyDelayRangeUpperBound: 1 ... 900)

        var taskScheduling: TaskScheduling = DummyTaskScheduling()
        if #available(iOS 13, *) {
            taskScheduling = BGTaskScheduler.shared
        }

        return BackgroundController(exposureController: dependencyProvider.dependency.exposureController,
                                    networkController: dependencyProvider.dependency.networkController,
                                    configuration: configuration,
                                    exposureManager: dependencyProvider.dependency.exposureManager,
                                    dataController: dependencyProvider.dependency.dataController,
                                    userNotificationCenter: dependencyProvider.userNotificationCenter,
                                    taskScheduler: taskScheduling,
                                    bundleIdentifier: dependencyProvider.bundleIdentifier,
                                    randomNumberGenerator: dependencyProvider.dependency.randomNumberGenerator)
    }
}

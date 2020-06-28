/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Foundation

/// @mockable
protocol BackgroundControlling {
    func scheduleTasks()
    func handle(task: BGTask)
}

protocol BackgroundDependency {
    var exposureController: ExposureControlling { get }
}

/// @mockable
protocol BackgroundControllerBuildable {
    func build() -> BackgroundControlling
}

private final class BackgroundControllerDependencyProvider: DependencyProvider<BackgroundDependency> {}

final class BackgroundControllerBuilder: Builder<BackgroundDependency>, BackgroundControllerBuildable {
    func build() -> BackgroundControlling {
        let dependencyProvider = BackgroundControllerDependencyProvider(dependency: dependency)
        return BackgroundController(exposureController: dependencyProvider.dependency.exposureController)
    }
}

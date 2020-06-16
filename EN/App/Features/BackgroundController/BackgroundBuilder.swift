/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import BackgroundTasks

/// @mockable
protocol BackgroundControlling {
    func schedule(taskIdentifier:String, launchHandler: @escaping (BGTask) -> Void)
}

/// @mockable
protocol BackgroundControllerBuildable {
    func build() -> BackgroundControlling
}

private final class BackgroundControllerDependencyProvider: DependencyProvider<EmptyDependency> {
}

final class BackgroundControllerBuilder: Builder<EmptyDependency>, BackgroundControllerBuildable {
    func build() -> BackgroundControlling {
        return BackgroundController()
    }
}

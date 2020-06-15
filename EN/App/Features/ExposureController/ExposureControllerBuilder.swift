/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol ExposureControlling {
    // MARK: - Setup
    
    func activate()
    
    // MARK: - Permissions
    
    func requestExposureNotificationPermission()
    func requestPushNotificationPermission()
    
    // MARK: - Exposure Notification
    
    func confirmExposureNotification()
}

/// @mockable
protocol ExposureControllerBuildable {
    func build() -> ExposureControlling
}

protocol ExposureControllerDependency {
    var mutableExposureStatusStream: MutableExposureStateStreaming { get }
}

private final class ExposureControllerDependencyProvider: DependencyProvider<ExposureControllerDependency> {
    lazy var exposureManager: ExposureManaging? = {
        let builder = ExposureManagerBuilder()
        
        return builder.build()
    }()
}

final class ExposureControllerBuilder: Builder<ExposureControllerDependency>, ExposureControllerBuildable {
    func build() -> ExposureControlling {
        let dependencyProvider = ExposureControllerDependencyProvider(dependency: dependency)
        
        return ExposureController(mutableStatusStream: dependencyProvider.dependency.mutableExposureStatusStream,
                                  exposureManager: dependencyProvider.exposureManager)
    }
}

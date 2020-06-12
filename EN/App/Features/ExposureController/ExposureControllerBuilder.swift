//
//  ExposureControllerBuilder.swift
//  EN
//
//  Created by Robin van Dijke on 12/06/2020.
//

import Foundation

/// @mockable
protocol ExposureControlling {
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

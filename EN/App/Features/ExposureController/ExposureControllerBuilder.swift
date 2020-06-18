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
    func requestPushNotificationPermission(_ completion: @escaping () -> ())

    // MARK: - Exposure Notification

    /// Sets the current `notified` state to false
    func confirmExposureNotification()

    // MARK: - Lab Flow

    /// Requests a human readable confirmation key
    ///
    /// - Parameter completion: Executed when key is available
    /// - Parameter confirmationKey: Human readable lab confirmation key
    /// - Parameter expiration: Key's expiration date
    func requestLabConfirmationKey(completion: @escaping (_ confirmationKey: String, _ expiration: Date) -> ())

    /// Requests keys from the framework and uploads them to the server.
    ///
    /// - Parameter completion: Executed when upload completes.
    /// - Parameter success: Indicates whether process was successful
    func requestUploadKeys(completion: @escaping (_ success: Bool) -> ())
}

/// @mockable
protocol ExposureControllerBuildable {
    func build() -> ExposureControlling
}

protocol ExposureControllerDependency {
    var mutableExposureStateStream: MutableExposureStateStreaming { get }
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

        return ExposureController(mutableStateStream: dependencyProvider.dependency.mutableExposureStateStream,
                                  exposureManager: dependencyProvider.exposureManager)
    }
}

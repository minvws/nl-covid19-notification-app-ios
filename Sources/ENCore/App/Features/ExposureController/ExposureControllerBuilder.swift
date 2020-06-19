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

    /// Represents a ConfirmationKey for the Lab Flow
    ///
    /// - Parameter confirmationKey: Human readable lab confirmation key
    /// - Parameter expiration: Key's expiration date
    typealias ConfirmationKey = (confirmationKey: String, expiration: Date)

    /// Requests a human readable confirmation key
    ///
    /// - Parameter completion: Executed when key is available
    /// - Parameter result: Result contains ConfirmationKey upon success or ExposureDataError on failure
    func requestLabConfirmationKey(completion: @escaping (_ result: Result<ConfirmationKey, ExposureDataError>) -> ())

    /// Requests keys from the framework and uploads them to the server.
    ///
    /// - Parameter completion: Executed when upload completes.
    /// - Parameter result: Result of the request
    func requestUploadKeys(completion: @escaping (_ result: ExposureControllerUploadKeysResult) -> ())
}

/// Result of the requestUploadKeys
///
enum ExposureControllerUploadKeysResult {
    /// Upload Keys request was finished successfully
    /// Keys will be uploaded in the background
    case success

    /// User did not authorize sharing their keys
    case notAuthorized

    /// Underlying failure - related to inactivity of the framework
    /// The UI should be prevent requesting keys when the framework
    /// is in an inactive state
    case inactive
}

/// @mockable
protocol ExposureControllerBuildable {
    func build() -> ExposureControlling
}

protocol ExposureControllerDependency {
    var mutableExposureStateStream: MutableExposureStateStreaming { get }
    var networkController: NetworkControlling { get }
    var storageController: StorageControlling { get }
}

private final class ExposureControllerDependencyProvider: DependencyProvider<ExposureControllerDependency>, ExposureDataControllerDependency {
    // MARK: - ExposureDataControllerDependency

    var networkController: NetworkControlling {
        return dependency.networkController
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }

    // MARK: - Private Dependencies

    lazy var exposureManager: ExposureManaging? = {
        let builder = ExposureManagerBuilder()

        return builder.build()
    }()

    var dataController: ExposureDataControlling {
        return ExposureDataControllerBuilder(dependency: self).build()
    }
}

final class ExposureControllerBuilder: Builder<ExposureControllerDependency>, ExposureControllerBuildable {
    func build() -> ExposureControlling {
        let dependencyProvider = ExposureControllerDependencyProvider(dependency: dependency)

        return ExposureController(mutableStateStream: dependencyProvider.dependency.mutableExposureStateStream,
                                  exposureManager: dependencyProvider.exposureManager,
                                  dataController: dependencyProvider.dataController)
    }
}

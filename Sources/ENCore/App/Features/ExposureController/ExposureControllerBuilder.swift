/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import UserNotifications

/// @mockable
protocol ExposureControlling: AnyObject {

    var lastExposureDate: Date? { get }

    // MARK: - Setup

    @discardableResult
    func activate(inBackgroundMode: Bool) -> AnyPublisher<(), Never>
    func deactivate()

    func getAppVersionInformation(_ completion: @escaping (ExposureDataAppVersionInformation?) -> ())
    func isAppDeactivated() -> AnyPublisher<Bool, ExposureDataError>
    func isTestPhase() -> AnyPublisher<Bool, Never>
    func getAppRefreshInterval() -> AnyPublisher<Int, ExposureDataError>
    func getDecoyProbability() -> AnyPublisher<Float, ExposureDataError>
    func getPadding() -> AnyPublisher<Padding, ExposureDataError>

    // MARK: - Updates

    func refreshStatus()

    func updateWhenRequired() -> AnyPublisher<(), ExposureDataError>
    func processPendingUploadRequests() -> AnyPublisher<(), ExposureDataError>

    func notifyUserIfRequired()

    // MARK: - Permissions

    func requestExposureNotificationPermission(_ completion: ((ExposureManagerError?) -> ())?)
    func requestPushNotificationPermission(_ completion: @escaping () -> ())

    // MARK: - Exposure KeySets

    func fetchAndProcessExposureKeySets() -> AnyPublisher<(), ExposureDataError>

    // MARK: - Exposure Notification

    /// Sets the current `notified` state to false
    func confirmExposureNotification()

    // MARK: - Lab Flow

    /// Requests a human readable confirmation key
    ///
    /// - Parameter completion: Executed when key is available
    /// - Parameter result: Result contains ConfirmationKey upon success or ExposureDataError on failure
    func requestLabConfirmationKey(completion: @escaping (_ result: Result<ExposureConfirmationKey, ExposureDataError>) -> ())

    /// Requests keys from the framework and uploads them to the server.
    ///
    /// - Parameter labConfirmationKey: LabConfirmationKey that was used prior to the request
    /// - Parameter completion: Executed when upload completes.
    /// - Parameter result: Result of the request
    func requestUploadKeys(forLabConfirmationKey labConfirmationKey: ExposureConfirmationKey,
                           completion: @escaping (_ result: ExposureControllerUploadKeysResult) -> ())

    // MARK: - Misc

    /// Sequentially runs `updateWhenRequired` then `processPendingUploadRequests`
    func updateAndProcessPendingUploads() -> AnyPublisher<(), ExposureDataError>

    /// Checks the status of the EN framework for the last 24h
    func exposureNotificationStatusCheck() -> AnyPublisher<(), Never>

    /// Checks if the app needs to be updated
    func appUpdateRequiredCheck() -> AnyPublisher<(), Never>

    /// Updates the treatment perspecive message
    func updateTreatmentPerspectiveMessage() -> AnyPublisher<TreatmentPerspective.Message, ExposureDataError>

    // MARK: - Onboarding

    /// Whether the user runs the app for the first time
    var isFirstRun: Bool { get }

    /// Whether the user has completed onboarding
    var didCompleteOnboarding: Bool { get set }
}

/// Represents a ConfirmationKey for the Lab Flow
///
/// - Parameter key: Human readable lab confirmation key
/// - Parameter expiration: Key's expiration date
protocol ExposureConfirmationKey {
    var key: String { get }
    var expiration: Date { get }
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

    /// This error happens when the given confirmationKey
    /// does not match the one that was returned from the
    /// requestLabConfirmationKey function.
    case invalidConfirmationKey

    /// An internal error happened when preparing the upload request
    case internalError

    /// The response is cached and should not be updated
    case responseCached
}

/// @mockable
protocol ExposureControllerBuildable {
    func build() -> ExposureControlling
}

protocol ExposureControllerDependency {
    var exposureManager: ExposureManaging { get }
    var mutableExposureStateStream: MutableExposureStateStreaming { get }
    var networkController: NetworkControlling { get }
    var storageController: StorageControlling { get }
    var networkStatusStream: NetworkStatusStreaming { get }
    var mutableBluetoothStateStream: MutableBluetoothStateStreaming { get }
}

private final class ExposureControllerDependencyProvider: DependencyProvider<ExposureControllerDependency>, ExposureDataControllerDependency {
    // MARK: - ExposureDataControllerDependency

    var networkController: NetworkControlling {
        return dependency.networkController
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }

    var exposureManager: ExposureManaging {
        return dependency.exposureManager
    }

    // MARK: - Private Dependencies

    fileprivate var dataController: ExposureDataControlling {
        return ExposureDataControllerBuilder(dependency: self).build()
    }

    fileprivate var userNotificationCenter: UserNotificationCenter {
        return UNUserNotificationCenter.current()
    }

    fileprivate var currentAppVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

final class ExposureControllerBuilder: Builder<ExposureControllerDependency>, ExposureControllerBuildable {
    func build() -> ExposureControlling {
        let dependencyProvider = ExposureControllerDependencyProvider(dependency: dependency)

        return ExposureController(mutableStateStream: dependencyProvider.dependency.mutableExposureStateStream,
                                  exposureManager: dependencyProvider.exposureManager,
                                  dataController: dependencyProvider.dataController,
                                  networkStatusStream: dependencyProvider.dependency.networkStatusStream,
                                  userNotificationCenter: dependencyProvider.userNotificationCenter,
                                  mutableBluetoothStateStream: dependencyProvider.dependency.mutableBluetoothStateStream,
                                  currentAppVersion: dependencyProvider.currentAppVersion)
    }
}

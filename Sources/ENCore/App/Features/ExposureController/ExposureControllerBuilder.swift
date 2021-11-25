/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import UserNotifications

/// @mockable(history: pause = true)
protocol ExposureControlling: AnyObject {

    var lastExposureDate: Date? { get }

    // MARK: - Setup

    @discardableResult
    func activate() -> Completable
    func deactivate()
    func postExposureManagerActivation()

    func pause(untilDate date: Date)
    func unpause()

    func getAppVersionInformation(_ completion: @escaping (ExposureDataAppVersionInformation?) -> ())
    func isAppDeactivated() -> Single<Bool>
    func getDecoyProbability() -> Single<Float>
    func getPadding() -> Single<Padding>

    // MARK: - Updates

    func refreshStatus(completion: (() -> ())?)

    func updateWhenRequired() -> Completable
    func processPendingUploadRequests() -> Completable

    // MARK: - Permissions

    func requestExposureNotificationPermission(_ completion: ((ExposureManagerError?) -> ())?)

    // MARK: - Exposure KeySets

    func fetchAndProcessExposureKeySets() -> Completable

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

    /// Updates the last app launch date
    func updateLastLaunch()

    /// Removes the unseen exposure notification date
    func clearUnseenExposureNotificationDate()

    func updateExposureFirstNotificationReceivedDate(_ date: Date)

    /// Sequentially runs `updateWhenRequired` then `processPendingUploadRequests`
    func updateAndProcessPendingUploads() -> Completable

    /// Shows a notification for expired lab key uploads and cleans up the requests
    func processExpiredUploadRequests() -> Completable

    /// Checks the status of the EN framework for the last 24h
    func exposureNotificationStatusCheck() -> Completable

    /// Checks if the app needs to be updated and returns true if it should
    func appShouldUpdateCheck() -> Single<AppUpdateInformation>

    /// Checks if the app needs to be updated and sends a local notification if it should
    func sendNotificationIfAppShouldUpdate() -> Completable

    /// Updates the treatment perspective message
    func updateTreatmentPerspective() -> Completable

    func getStoredAppConfigFeatureFlags() -> [ApplicationConfiguration.FeatureFlag]?

    func getScheduledNotificaton() -> ApplicationConfiguration.ScheduledNotification?

    func getStoredShareKeyURL() -> String?

    // MARK: - Onboarding

    /// Whether the user runs the app for the first time
    var isFirstRun: Bool { get }

    /// Whether the user has completed onboarding
    var didCompleteOnboarding: Bool { get set }

    /// All announcements that the user has seen within the app or during the onboarding proces
    var seenAnnouncements: [Announcement] { get set }

    /// Checks the last date the user opened the app and trigers a notificaiton if its been longer than 3 hours from the last exposure.
    func lastOpenedNotificationCheck() -> Completable

    var exposureManager: ExposureManaging { get }

    /// Get the latest  TEK processing date
    func lastTEKProcessingDate() -> Observable<Date?>

    func updateLastExposureProcessingDateSubject()
}

/// Represents a ConfirmationKey for the Lab Flow
///
/// - Parameter key: Human readable lab confirmation key
/// - Parameter expiration: Key's expiration date
/// @mockable
protocol ExposureConfirmationKey {
    var key: String { get }
    var expiration: Date { get }
}

extension ExposureConfirmationKey {
    var isValid: Bool { expiration >= currentDate() }
}

struct AppUpdateInformation {
    let shouldUpdate: Bool
    let versionInformation: ExposureDataAppVersionInformation?
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
    var applicationSignatureController: ApplicationSignatureControlling { get }
    var networkStatusStream: NetworkStatusStreaming { get }
    var dataController: ExposureDataControlling { get }
}

private final class ExposureControllerDependencyProvider: DependencyProvider<ExposureControllerDependency>, ExposureDataControllerDependency {
    // MARK: - ExposureDataControllerDependency

    var networkController: NetworkControlling {
        return dependency.networkController
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }

    var applicationSignatureController: ApplicationSignatureControlling {
        return dependency.applicationSignatureController
    }

    var exposureManager: ExposureManaging {
        return dependency.exposureManager
    }

    var cellularDataStream: CellularDataStreaming {
        CellularDataStream()
    }

    // MARK: - Private Dependencies

    fileprivate var dataController: ExposureDataControlling {
        return dependency.dataController
    }

    fileprivate var userNotificationController: UserNotificationControlling {
        return UserNotificationController(storageController: storageController)
    }

    fileprivate var currentAppVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
}

final class ExposureControllerBuilder: Builder<ExposureControllerDependency>, ExposureControllerBuildable {
    func build() -> ExposureControlling {
        let dependencyProvider = ExposureControllerDependencyProvider(dependency: dependency)

        return ExposureController(mutableStateStream: dependencyProvider.dependency.mutableExposureStateStream,
                                  exposureManager: dependencyProvider.exposureManager,
                                  dataController: dependencyProvider.dataController,
                                  networkStatusStream: dependencyProvider.dependency.networkStatusStream,
                                  userNotificationController: dependencyProvider.userNotificationController,
                                  currentAppVersion: dependencyProvider.currentAppVersion,
                                  cellularDataStream: dependencyProvider.cellularDataStream)
    }
}

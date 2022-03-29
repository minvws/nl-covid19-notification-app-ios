/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

enum ExposureDataError: Error, Equatable {
    case networkUnreachable
    case serverError
    case internalError
    case inactive(ExposureStateInactiveState)
    case notAuthorized
    case responseCached
    case signatureValidationFailed
}

struct ExposureDataAppVersionInformation {
    let minimumVersion: String
    let minimumVersionMessage: String
    let appStoreURL: String
}

/// @mockable(history:updateLastSuccessfulExposureProcessingDate=true;addPreviousExposureDate=true;isKnownPreviousExposureDate=true)
protocol ExposureDataControlling: AnyObject {
    // MARK: - Exposure Detection

    var lastExposure: ExposureReport? { get }
    func updateLastExposureProcessingDateSubject()
    var lastSuccessfulExposureProcessingDateObservable: Observable<Date?> { get }
    var lastSuccessfulExposureProcessingDate: Date? { get }
    func updateLastSuccessfulExposureProcessingDate(_ date: Date)
    var lastLocalNotificationExposureDate: Date? { get }
    var exposureFirstNotificationReceivedDate: Date? { get }
    func updateExposureFirstNotificationReceivedDate(_ date: Date)
    var lastENStatusCheckDate: Date? { get }
    var lastAppLaunchDate: Date? { get }
    var lastUnseenExposureNotificationDate: Date? { get }
    var ignoreFirstV2Exposure: Bool { get set }

    func setLastDecoyProcessDate(_ date: Date)
    var canProcessDecoySequence: Bool { get }

    func removeLastExposure() -> Completable
    func removeFirstNotificationReceivedDate() -> Completable
    func fetchAndProcessExposureKeySets(exposureManager: ExposureManaging) -> Completable
    func setLastENStatusCheckDate(_ date: Date)
    func setLastAppLaunchDate(_ date: Date)
    func clearLastUnseenExposureNotificationDate()

    // MARK: - Previous known exposure dates

    func addPreviousExposureDate(_ exposureDate: Date) -> Completable
    func isKnownPreviousExposureDate(_ exposureDate: Date) -> Bool
    func removePreviousExposureDateIfNeeded() -> Completable

    // MARK: - Lab Flow

    func processPendingUploadRequests() -> Completable
    func processExpiredUploadRequests() -> Completable
    func requestLabConfirmationKey() -> Single<LabConfirmationKey>
    func upload(diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> Completable

    // MARK: - Misc

    func getAppVersionInformation() -> Single<ExposureDataAppVersionInformation>
    func getStoredAppConfigFeatureFlags() -> [ApplicationConfiguration.FeatureFlag]?
    func getScheduledNotificaton() -> ApplicationConfiguration.ScheduledNotification?
    func getStoredShareKeyURL() -> String?
    func getStoredCoronaTestURL() -> String

    func isAppDeactivated() -> Single<Bool>
    func getDecoyProbability() -> Single<Float>
    func getPadding() -> Single<Padding>
    func getAppointmentPhoneNumber() -> Single<String>
    func updateLastLocalNotificationExposureDate(_ date: Date)
    func updateTreatmentPerspective() -> Completable
    var isFirstRun: Bool { get }
    var didCompleteOnboarding: Bool { get set }
    var seenAnnouncements: [Announcement] { get set }

    // MARK: - Pausing

    var pauseEndDateObservable: Observable<Date?> { get }
    var isAppPaused: Bool { get }
    var pauseEndDate: Date? { get set }
    var hidePauseInformation: Bool { get set }
}

protocol ExposureDataControllerBuildable {
    func build() -> ExposureDataControlling
}

protocol ExposureDataControllerDependency {
    var networkController: NetworkControlling { get }
    var storageController: StorageControlling { get }
    var applicationSignatureController: ApplicationSignatureControlling { get }
}

private final class ExposureDataControllerDependencyProvider: DependencyProvider<ExposureDataControllerDependency>, ExposureDataOperationProviderDependency {
    // MARK: - ExposureDataOperationProviderDependency

    var networkController: NetworkControlling {
        return dependency.networkController
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }

    var applicationSignatureController: ApplicationSignatureControlling {
        return dependency.applicationSignatureController
    }

    var environmentController: EnvironmentControlling {
        return EnvironmentController()
    }

    // MARK: - Private Dependencies

    var operationProvider: ExposureDataOperationProvider {
        return ExposureDataOperationProviderBuilder(dependency: self).build()
    }
}

final class ExposureDataControllerBuilder: Builder<ExposureDataControllerDependency>, ExposureDataControllerBuildable {
    func build() -> ExposureDataControlling {
        let dependencyProvider = ExposureDataControllerDependencyProvider(dependency: dependency)

        let controller = ExposureDataController(operationProvider: dependencyProvider.operationProvider,
                                                storageController: dependencyProvider.storageController,
                                                environmentController: dependencyProvider.environmentController)

        controller.performInitialisationTasks()

        return controller
    }
}

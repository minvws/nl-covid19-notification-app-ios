/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

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

/// @mockable
protocol ExposureDataControlling: AnyObject {

    // MARK: - Exposure Detection

    var lastExposure: ExposureReport? { get }
    var lastSuccessfulExposureProcessingDatePublisher: AnyPublisher<Date?, Never> { get }
    var lastSuccessfulExposureProcessingDate: Date? { get }
    func updateLastSuccessfulExposureProcessingDate(_ date: Date, done: @escaping () -> ())
    var lastLocalNotificationExposureDate: Date? { get }
    var lastENStatusCheckDate: Date? { get }
    var lastAppLaunchDate: Date? { get }
    var lastUnseenExposureNotificationDate: Date? { get }

    func setLastDecoyProcessDate(_ date: Date)
    var canProcessDecoySequence: Bool { get }

    func removeLastExposure() -> AnyPublisher<(), Never>
    func fetchAndProcessExposureKeySets(exposureManager: ExposureManaging) -> AnyPublisher<(), ExposureDataError>
    func setLastENStatusCheckDate(_ date: Date)
    func setLastAppLaunchDate(_ date: Date)
    func clearLastUnseenExposureNotificationDate()

    // MARK: - Lab Flow

    func processPendingUploadRequests() -> AnyPublisher<(), ExposureDataError>
    func processExpiredUploadRequests() -> AnyPublisher<(), ExposureDataError>
    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, ExposureDataError>
    func upload(diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), ExposureDataError>

    // MARK: - Misc

    func getAppVersionInformation() -> AnyPublisher<ExposureDataAppVersionInformation?, ExposureDataError>
    func isAppDectivated() -> AnyPublisher<Bool, ExposureDataError>
    func getAppRefreshInterval() -> AnyPublisher<Int, ExposureDataError>
    func getDecoyProbability() -> AnyPublisher<Float, ExposureDataError>
    func getPadding() -> AnyPublisher<Padding, ExposureDataError>
    func getAppointmentPhoneNumber() -> AnyPublisher<String, ExposureDataError>
    func updateLastLocalNotificationExposureDate(_ date: Date)
    func requestTreatmentPerspective() -> AnyPublisher<TreatmentPerspective, ExposureDataError>
    var isFirstRun: Bool { get }
    var didCompleteOnboarding: Bool { get set }
    var seenAnnouncements: [Announcement] { get set }

    // MARK: - Pausing

    var pauseEndDatePublisher: AnyPublisher<Date?, Never> { get }
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

        return ExposureDataController(operationProvider: dependencyProvider.operationProvider,
                                      storageController: dependencyProvider.storageController,
                                      environmentController: dependencyProvider.environmentController)
    }
}

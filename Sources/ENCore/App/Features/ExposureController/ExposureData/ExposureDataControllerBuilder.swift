/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
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

/// @mockable
protocol ExposureDataControlling: AnyObject {

    // MARK: - Exposure Detection

    var lastExposure: ExposureReport? { get }
    var lastSuccessfulProcessingDate: Date? { get }
    var lastLocalNotificationExposureDate: Date? { get }
    var lastENStatusCheckDate: Date? { get }
    var lastAppLaunchDate: Date? { get }
    var lastUnseenExposureNotificationDate: Date? { get }

    func setLastDecoyProcessDate(_ date: Date)
    var canProcessDecoySequence: Bool { get }

    func removeLastExposure() -> Completable
    func fetchAndProcessExposureKeySets(exposureManager: ExposureManaging) -> AnyPublisher<(), ExposureDataError>
    func setLastENStatusCheckDate(_ date: Date)
    func setLastAppLaunchDate(_ date: Date)
    func clearLastUnseenExposureNotificationDate()

    // MARK: - Lab Flow

    func processPendingUploadRequests() -> AnyPublisher<(), ExposureDataError>
    func processExpiredUploadRequests() -> AnyPublisher<(), ExposureDataError>
    func requestLabConfirmationKey() -> Observable<LabConfirmationKey>
    func upload(diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> Observable<()>

    // MARK: - Misc

    func getAppVersionInformation() -> Observable<ExposureDataAppVersionInformation>
    func isAppDeactivated() -> Observable<Bool>
    func getDecoyProbability() -> Single<Float>
    func getPadding() -> Single<Padding>
    func getAppointmentPhoneNumber() -> Observable<String>
    func updateLastLocalNotificationExposureDate(_ date: Date)
    func requestTreatmentPerspective() -> Observable<TreatmentPerspective>
    var isFirstRun: Bool { get }
    var didCompleteOnboarding: Bool { get set }
    var seenAnnouncements: [Announcement] { get set }
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

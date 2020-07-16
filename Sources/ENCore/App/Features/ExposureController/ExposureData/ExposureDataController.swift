/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct ExposureDataStorageKey {
    static let labConfirmationKey = CodableStorageKey<LabConfirmationKey>(name: "labConfirmationKey",
                                                                          storeType: .secure)
    static let lastUploadedRollingStartNumber = CodableStorageKey<Int32>(name: "lastUploadedRollingStartNumber",
                                                                         storeType: .secure)
    static let appManifest = CodableStorageKey<ApplicationManifest>(name: "appManifest",
                                                                    storeType: .insecure(volatile: true))
    static let appConfiguration = CodableStorageKey<ApplicationConfiguration>(name: "appConfiguration",
                                                                              storeType: .insecure(volatile: true))
    static let exposureKeySetsHolders = CodableStorageKey<[ExposureKeySetHolder]>(name: "exposureKeySetsHolders",
                                                                                  storeType: .insecure(volatile: false))
    static let lastExposureReport = CodableStorageKey<ExposureReport>(name: "exposureReport",
                                                                      storeType: .secure)
    static let lastExposureProcessingDate = CodableStorageKey<Date>(name: "lastExposureProcessingDate",
                                                                    storeType: .insecure(volatile: false))
    static let lastLocalNotificationExposureDate = CodableStorageKey<Date>(name: "lastLocalNotificationExposureDate",
                                                                           storeType: .insecure(volatile: false))
    static let exposureConfiguration = CodableStorageKey<ExposureRiskConfiguration>(name: "exposureConfiguration",
                                                                                    storeType: .insecure(volatile: false))
    static let pendingLabUploadRequests = CodableStorageKey<[PendingLabConfirmationUploadRequest]>(name: "pendingLabUploadRequests",
                                                                                                   storeType: .secure)
}

final class ExposureDataController: ExposureDataControlling, Logging {

    private var disposeBag = Set<AnyCancellable>()

    init(operationProvider: ExposureDataOperationProvider,
         storageController: StorageControlling) {
        self.operationProvider = operationProvider
        self.storageController = storageController
    }

    // MARK: - ExposureDataControlling

    // MARK: - Exposure Detection

    func fetchAndProcessExposureKeySets(exposureManager: ExposureManaging) -> AnyPublisher<(), ExposureDataError> {
        return requestApplicationConfiguration()
            .flatMap { _ in self.fetchAndStoreExposureKeySets() }
            .flatMap { self.processStoredExposureKeySets(exposureManager: exposureManager) }
            .share()
            .eraseToAnyPublisher()
    }

    var lastExposure: ExposureReport? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)
    }

    var lastLocalNotificationExposureDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastLocalNotificationExposureDate)
    }

    var lastSuccessfulFetchDate: Date {
        if let date = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate) {
            return date
        }

        // no date has been set before - set the current date/time to prevent showing
        // a no-update warning immediately from the beginning.
        // Only when the user has not had internet for x hours after opening the app
        // a message should be shown
        let date = Date()
        storageController.store(object: date, identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate, completion: { _ in })

        return date
    }

    func removeLastExposure() -> AnyPublisher<(), Never> {
        return Future { promise in
            self.storageController.removeData(for: ExposureDataStorageKey.lastExposureReport) { _ in
                promise(.success(()))
            }
        }
        .share()
        .eraseToAnyPublisher()
    }

    func processStoredExposureKeySets(exposureManager: ExposureManaging) -> AnyPublisher<(), ExposureDataError> {
        return requestExposureRiskConfiguration()
            .flatMap { configuration in
                return self.operationProvider
                    .processExposureKeySetsOperation(exposureManager: exposureManager,
                                                     configuration: configuration)
                    .execute()
            }
            .eraseToAnyPublisher()
    }

    func fetchAndStoreExposureKeySets() -> AnyPublisher<(), ExposureDataError> {
        return requestApplicationManifest()
            .map { (manifest: ApplicationManifest) -> [String] in manifest.exposureKeySetsIdentifiers }
            .flatMap { exposureKeySetsIdentifiers in
                self.operationProvider
                    .requestExposureKeySetsOperation(identifiers: exposureKeySetsIdentifiers)
                    .execute()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - LabFlow

    func processPendingUploadRequests() -> AnyPublisher<(), ExposureDataError> {
        return requestApplicationConfiguration()
            .map { (configuration: ApplicationConfiguration) in
                Padding(minimumRequestSize: configuration.requestMinimumSize, maximumRequestSize: configuration.requestMaximumSize)
            }.flatMap { (padding: Padding) in
                return self.operationProvider
                    .processPendingLabConfirmationUploadRequestsOperation(padding: padding)
                    .execute()
            }.eraseToAnyPublisher()
    }

    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, ExposureDataError> {
        return requestApplicationConfiguration()
            .map { (configuration: ApplicationConfiguration) in
                Padding(minimumRequestSize: configuration.requestMinimumSize,
                        maximumRequestSize: configuration.requestMaximumSize)
            }
            .flatMap { (padding: Padding) in
                return self.operationProvider
                    .requestLabConfirmationKeyOperation(padding: padding)
                    .execute()
            }
            .eraseToAnyPublisher()
    }

    func upload(diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), ExposureDataError> {
        return requestApplicationConfiguration()
            .map { (configuration: ApplicationConfiguration) in
                Padding(minimumRequestSize: configuration.requestMinimumSize,
                        maximumRequestSize: configuration.requestMaximumSize)
            }
            .flatMap { (padding: Padding) in
                return self.operationProvider
                    .uploadDiagnosisKeysOperation(diagnosisKeys: diagnosisKeys, labConfirmationKey: labConfirmationKey, padding: padding)
                    .execute()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Misc

    func getAppVersionInformation() -> AnyPublisher<ExposureDataAppVersionInformation?, ExposureDataError> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return ExposureDataAppVersionInformation(minimumVersion: applicationConfiguration.minimumVersion,
                                                         minimumVersionMessage: applicationConfiguration.minimumVersionMessage,
                                                         appStoreURL: applicationConfiguration.appStoreURL)
            }
            .eraseToAnyPublisher()
    }

    func updateLastLocalNotificationExposureDate(_ date: Date) {
        storageController.store(object: date, identifiedBy: ExposureDataStorageKey.lastLocalNotificationExposureDate, completion: { _ in })
    }

    // MARK: - Private

    private func requestApplicationConfiguration() -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        return requestApplicationManifest()
            .flatMap { manifest in
                return self
                    .operationProvider
                    .requestAppConfigurationOperation(identifier: manifest.appConfigurationIdentifier)
                    .execute()
            }
            .eraseToAnyPublisher()
    }

    private func requestApplicationManifest() -> AnyPublisher<ApplicationManifest, ExposureDataError> {
        return operationProvider
            .requestManifestOperation
            .execute()
    }

    private func requestExposureRiskConfiguration() -> AnyPublisher<ExposureConfiguration, ExposureDataError> {
        return requestApplicationManifest()
            .map { (manifest: ApplicationManifest) in manifest.riskCalculationParametersIdentifier }
            .flatMap { identifier in
                self.operationProvider
                    .requestExposureConfigurationOperation(identifier: identifier)
                    .execute()
            }
            .eraseToAnyPublisher()
    }

    private let operationProvider: ExposureDataOperationProvider
    private let storageController: StorageControlling
}

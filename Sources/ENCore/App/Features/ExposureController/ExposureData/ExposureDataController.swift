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
    static let exposureConfiguration = CodableStorageKey<ExposureRiskConfiguration>(name: "exposureConfiguration",
                                                                                    storeType: .insecure(volatile: false))
    static let pendingLabUploadRequests = CodableStorageKey<[PendingLabConfirmationUploadRequest]>(name: "pendingLabUploadRequests",
                                                                                                   storeType: .secure)
}

final class ExposureDataController: ExposureDataControlling {

    private var disposeBag = Set<AnyCancellable>()

    init(operationProvider: ExposureDataOperationProvider,
         storageController: StorageControlling) {
        self.operationProvider = operationProvider
        self.storageController = storageController
    }

    // MARK: - ExposureDataControlling

    // MARK: - Exposure Detection

    func fetchAndProcessExposureKeySets(exposureManager: ExposureManaging) -> AnyPublisher<(), ExposureDataError> {
        return fetchAndStoreExposureKeySets()
            .flatMap { self.processStoredExposureKeySets(exposureManager: exposureManager) }
            .eraseToAnyPublisher()
    }

    var lastExposure: ExposureReport? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)
    }

    func removeLastExposure() -> Future<(), Never> {
        return Future { promise in
            self.storageController.removeData(for: ExposureDataStorageKey.lastExposureReport) { _ in
                promise(.success(()))
            }
        }
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

    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, ExposureDataError> {
        let operation = operationProvider.requestLabConfirmationKeyOperation

        return operation.execute()
    }

    func upload(diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), ExposureDataError> {
        let operation = operationProvider.uploadDiagnosisKeysOperation(diagnosisKeys: diagnosisKeys,
                                                                       labConfirmationKey: labConfirmationKey)

        return operation.execute()
    }

    // MARK: - Private

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

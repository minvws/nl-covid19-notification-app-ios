/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

final class UploadDiagnosisKeysDataOperation: ExposureDataOperation {
    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         diagnosisKeys: [DiagnosisKey],
         labConfirmationKey: LabConfirmationKey,
         padding: Padding) {
        self.networkController = networkController
        self.storageController = storageController
        self.diagnosisKeys = diagnosisKeys
        self.labConfirmationKey = labConfirmationKey
        self.padding = padding
    }

    func execute() -> AnyPublisher<(), ExposureDataError> {
        let keys = filterOutAlreadyUploadedKeys(diagnosisKeys)

        return networkController
            // execute network request
            .postKeys(keys: keys, labConfirmationKey: labConfirmationKey, padding: padding)
            .mapError { (error: NetworkError) -> ExposureDataError in error.asExposureDataError }
            // store rolling start numbers for successfully uploaded keys
            .flatMap { _ in self.storeRollingStartNumbers(for: keys) }
            .catch { error in self.scheduleRetryWhenFailed(error: error, diagnosisKeys: keys, labConfirmationKey: self.labConfirmationKey) }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func storeRollingStartNumbers(for keys: [DiagnosisKey]) -> AnyPublisher<(), ExposureDataError> {
        let rollingStartNumbers = keys.map { $0.rollingStartNumber }

        return Future { promise in
            self.storageController.requestExclusiveAccess { storageController in
                let currentRollingStartNumbers = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.uploadedRollingStartNumbers) ?? []

                let allRollingStartNumbers = rollingStartNumbers + currentRollingStartNumbers

                self.storageController.store(object: allRollingStartNumbers,
                                             identifiedBy: ExposureDataStorageKey.uploadedRollingStartNumbers) { error in
                    // cannot store - ignore and upload the whole set again next time
                    promise(.success(()))
                }
            }
        }
        .share()
        .eraseToAnyPublisher()
    }

    private func scheduleRetryWhenFailed(error: ExposureDataError, diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), ExposureDataError> {

        return Future { promise in
            let retryRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: labConfirmationKey,
                                                                   diagnosisKeys: diagnosisKeys,
                                                                   expiryDate: labConfirmationKey.expiration)

            self.storageController.requestExclusiveAccess { storageController in
                var requests = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []

                requests.append(retryRequest)

                storageController.store(object: requests, identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) { _ in
                    promise(.success(()))
                }
            }
        }
        .share()
        .eraseToAnyPublisher()
    }

    private func filterOutAlreadyUploadedKeys(_ keys: [DiagnosisKey]) -> [DiagnosisKey] {
        // get successfully uploaded rollingStartNumbers
        let rollingStartNumbersStorageKey = ExposureDataStorageKey.uploadedRollingStartNumbers
        let uploadedRollingStartNumbers = storageController.retrieveObject(identifiedBy: rollingStartNumbersStorageKey) ?? []

        // get pending operations
        let pendingOperationsStorageKey = ExposureDataStorageKey.pendingLabUploadRequests
        let pendingOperations = storageController.retrieveObject(identifiedBy: pendingOperationsStorageKey) ?? []
        let pendingRollingStartNumbers = pendingOperations.flatMap { $0.diagnosisKeys.map { $0.rollingStartNumber } }

        let isNotPendingOrUploaded: (DiagnosisKey) -> Bool = { diagnosisKey in
            let rollingStartNumber = diagnosisKey.rollingStartNumber

            return uploadedRollingStartNumbers.contains(rollingStartNumber) == false
                && pendingRollingStartNumbers.contains(rollingStartNumber) == false
        }

        return keys.filter(isNotPendingOrUploaded)
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let diagnosisKeys: [DiagnosisKey]
    private let labConfirmationKey: LabConfirmationKey
    private let padding: Padding
}

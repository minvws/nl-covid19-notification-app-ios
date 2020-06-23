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
         labConfirmationKey: LabConfirmationKey) {
        self.networkController = networkController
        self.storageController = storageController
        self.diagnosisKeys = diagnosisKeys
        self.labConfirmationKey = labConfirmationKey
    }

    func execute() -> AnyPublisher<(), ExposureDataError> {
        let keys = filterOutAlreadyUploadedKeys(diagnosisKeys)

        return networkController
            .postKeys(keys: keys, labConfirmationKey: labConfirmationKey)
            .mapError { (error: NetworkError) -> ExposureDataError in error.asExposureDataError }
            .flatMap { self.storeLastRollingStartNumber(for: keys) }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func storeLastRollingStartNumber(for keys: [DiagnosisKey]) -> AnyPublisher<(), ExposureDataError> {
        let rollingStartNumbers = keys.map { $0.rollingStartNumber }
        guard let highestRollingStartNumber = rollingStartNumbers.max() else {
            // cannot find highest rolling number, don't store anything and upload the whole set again next time
            return Just(())
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        return Future { promise in
            self.storageController.store(object: highestRollingStartNumber,
                                         identifiedBy: ExposureDataStorageKey.lastUploadedRollingStartNumber) { error in
                // cannot store - ignore and upload the whole set again next time
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }

    private func filterOutAlreadyUploadedKeys(_ keys: [DiagnosisKey]) -> [DiagnosisKey] {
        let storageKey = ExposureDataStorageKey.lastUploadedRollingStartNumber
        let storedLastRollingStartNumber = storageController.retrieveObject(identifiedBy: storageKey,
                                                                            ofType: Int32.self)

        guard let lastRollingStartNumber = storedLastRollingStartNumber else {
            return keys
        }

        let keyHasHigherRollingStartNumber: (DiagnosisKey) -> Bool = { key in
            key.rollingStartNumber > lastRollingStartNumber
        }

        return keys.filter(keyHasHigherRollingStartNumber)
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let diagnosisKeys: [DiagnosisKey]
    private let labConfirmationKey: LabConfirmationKey
}

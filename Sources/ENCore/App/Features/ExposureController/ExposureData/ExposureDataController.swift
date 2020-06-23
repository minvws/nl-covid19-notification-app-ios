/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct ExposureDataStorageKey {
    static var labConfirmationKey = AnyStoreKey(name: "labConfirmationKey", storeType: .secure)
    static var lastUploadedRollingStartNumber = AnyStoreKey(name: "lastUploadedRollingStartNumber", storeType: .secure)
}

final class ExposureDataController: ExposureDataControlling {

    init(operationProvider: ExposureDataOperationProvider) {
        self.operationProvider = operationProvider
    }

    // MARK: - Operations

    func scheduleOperations() {
        // TODO: Implement
    }

    // MARK: - ExposureDataControlling

    func fetchAndProcessExposureKeySets() -> Future<(), Never> {
        return Future { promise in
            promise(.success(()))
        }
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

    private let operationProvider: ExposureDataOperationProvider
}

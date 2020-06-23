/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct ExposureDataStorageKey {
    static let labConfirmationKey = AnyStoreKey(name: "labConfirmationKey", storeType: .secure)
    static let lastUploadedRollingStartNumber = AnyStoreKey(name: "lastUploadedRollingStartNumber", storeType: .secure)
    static let appManifest = AnyStoreKey(name: "appManifest", storeType: .insecure(volatile: true))
    static let appConfiguration = AnyStoreKey(name: "appConfiguration", storeType: .insecure(volatile: true))
}

final class ExposureDataController: ExposureDataControlling {

    private var disposeBag = Set<AnyCancellable>()

    init(operationProvider: ExposureDataOperationProvider) {
        self.operationProvider = operationProvider

        fetchAndProcessExposureKeySets()
            .sink { () in

            }.store(in: &disposeBag)
    }

    // MARK: - Operations

    func scheduleOperations() {
        // TODO: Implement
    }

    // MARK: - ExposureDataControlling

    func fetchAndProcessExposureKeySets() -> AnyPublisher<(), Never> {
        return Just(()).eraseToAnyPublisher()
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

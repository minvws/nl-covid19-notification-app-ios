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
}

final class ExposureDataController: ExposureDataControlling {

    init(operationProvider: ExposureDataOperationProvider) {
        self.operationProvider = operationProvider
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
            .setFailureType(to: ExposureDataError.self)
//            .flatMap { labConfirmationKey -> AnyPublisher<LabConfirmationKey, ExposureDataError> in
//                guard let labConfirmationKey = labConfirmationKey else {
//                    return Fail(error: ExposureDataError.serverUnreachable).eraseToAnyPublisher()
//                }
//
//                return Just(labConfirmationKey)
//                    .setFailureType(to: ExposureDataError.self)
//                    .eraseToAnyPublisher()
//        }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private let operationProvider: ExposureDataOperationProvider
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct LabConfirmationKey: Codable {
    let identifier: String
    let bucketIdentifier: Data
    let confirmationKey: Data
    let validUntil: Date
}

extension LabConfirmationKey {
    var isValid: Bool { validUntil >= Date() }
}

final class RequestLabConfirmationKeyDataOperation: ExposureDataOperation {
    typealias Result = LabConfirmationKey

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<LabConfirmationKey, ExposureDataError> {
        return retrieveStoredKey()
            .flatMap { confirmationKey -> AnyPublisher<LabConfirmationKey, ExposureDataError> in
                if let confirmationKey = confirmationKey, confirmationKey.isValid {
                    return Just(confirmationKey)
                        .setFailureType(to: ExposureDataError.self)
                        .eraseToAnyPublisher()
                }

                return self.requestNewKey()
                    .flatMap(self.storeReceivedKey(key:))
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func retrieveStoredKey() -> AnyPublisher<LabConfirmationKey?, ExposureDataError> {
        let key = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.labConfirmationKey,
                                                   ofType: LabConfirmationKey.self)

        return Just(key)
            .setFailureType(to: ExposureDataError.self)
            .eraseToAnyPublisher()
    }

    private func storeReceivedKey(key: LabConfirmationKey) -> AnyPublisher<LabConfirmationKey, ExposureDataError> {
        return Future { promise in
            self.storageController.store(object: key,
                                         identifiedBy: ExposureDataStorageKey.labConfirmationKey,
                                         completion: { _ in
                                             promise(.success(key))
            })
        }
        .eraseToAnyPublisher()
    }

    private func requestNewKey() -> AnyPublisher<LabConfirmationKey, ExposureDataError> {
        return networkController
            .requestLabConfirmationKey()
            .mapError { (error: NetworkError) -> ExposureDataError in error.asExposureDataError }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

private extension NetworkError {
    var asExposureDataError: ExposureDataError {
        switch self {
        case .invalidResponse:
            return .serverError
        case .serverNotReachable:
            return .networkUnreachable
        }
    }
}

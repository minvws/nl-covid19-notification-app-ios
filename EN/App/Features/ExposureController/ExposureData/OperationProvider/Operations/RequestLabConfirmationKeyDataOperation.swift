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
    var isValid: Bool { validUntil < Date() }
}

final class RequestLabConfirmationKeyDataOperation: ExposureDataOperation {
    typealias Result = LabConfirmationKey
    typealias Error = Never // TODO: Define correct error

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<LabConfirmationKey, Never> {
        return retrieveStoredKey()
            .flatMap { confirmationKey -> AnyPublisher<LabConfirmationKey, Never> in
                if let confirmationKey = confirmationKey {
                    return Just(confirmationKey).eraseToAnyPublisher()
                }

                return self.requestNewKey()
                    .assertNoFailure()
                    .flatMap(self.storeReceivedKey(key:))
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func retrieveStoredKey() -> AnyPublisher<LabConfirmationKey?, Never> {
        let key = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.labConfirmationKey,
                                                   ofType: LabConfirmationKey.self)

        return Just(key).eraseToAnyPublisher()
    }

    private func storeReceivedKey(key: LabConfirmationKey) -> AnyPublisher<LabConfirmationKey, Never> {
        return Future { promise in
            self.storageController.store(object: key,
                                         identifiedBy: ExposureDataStorageKey.labConfirmationKey,
                                         completion: { _ in
                                             promise(.success(key))
            })
        }
        .eraseToAnyPublisher()
    }

    private func requestNewKey() -> AnyPublisher<LabConfirmationKey, NetworkError> {
        return networkController.requestLabConfirmationKey()
    }

    // MARK: - Private

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift
import ENFoundation

struct LabConfirmationKey: Codable, Equatable {
    let identifier: String
    let bucketIdentifier: Data
    let confirmationKey: Data
    let validUntil: Date
}

extension LabConfirmationKey {
    var isValid: Bool { validUntil >= currentDate() }
}

/// @mockable
protocol RequestLabConfirmationKeyDataOperationProtocol {
    func execute() -> Single<LabConfirmationKey>
}

final class RequestLabConfirmationKeyDataOperation: RequestLabConfirmationKeyDataOperationProtocol {

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         padding: Padding) {
        self.networkController = networkController
        self.storageController = storageController
        self.padding = padding
    }

    // MARK: - ExposureDataOperation

    func execute() -> Single<LabConfirmationKey> {

        if let storedConfirmationKey = retrieveStoredKey(), storedConfirmationKey.isValid {
            return .just(storedConfirmationKey)
        }

        return self.requestNewKey()
            .flatMap(self.storeReceivedKey(key:))
            .subscribe(on: MainScheduler.instance)
    }

    private func retrieveStoredKey() -> LabConfirmationKey? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.labConfirmationKey)
    }

    private func storeReceivedKey(key: LabConfirmationKey) -> Single<LabConfirmationKey> {
        return .create { observer in

            self.storageController.store(object: key,
                                         identifiedBy: ExposureDataStorageKey.labConfirmationKey,
                                         completion: { error in
                                             if error != nil {
                                                 observer(.failure(ExposureDataError.internalError))
                                             } else {
                                                 observer(.success(key))
                                             }
                                         })

            return Disposables.create()
        }
    }

    private func requestNewKey() -> Single<LabConfirmationKey> {
        return networkController
            .requestLabConfirmationKey(padding: padding)
            .catch { error in
                throw (error as? NetworkError)?.asExposureDataError ?? ExposureDataError.internalError
            }
    }

    // MARK: - Private

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let padding: Padding
}

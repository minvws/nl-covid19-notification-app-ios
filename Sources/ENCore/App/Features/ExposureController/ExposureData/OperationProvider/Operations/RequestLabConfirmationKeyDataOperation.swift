/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

struct LabConfirmationKey: Codable, Equatable {
    let identifier: String
    let bucketIdentifier: Data
    let confirmationKey: Data
    let validUntil: Date
}

extension LabConfirmationKey {
    var isValid: Bool { validUntil >= Date() }
}

protocol RequestLabConfirmationKeyDataOperationProtocol {
    func execute() -> Observable<LabConfirmationKey>
}

final class RequestLabConfirmationKeyDataOperation: RequestLabConfirmationKeyDataOperationProtocol {
    typealias Result = LabConfirmationKey

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         padding: Padding) {
        self.networkController = networkController
        self.storageController = storageController
        self.padding = padding
    }

    // MARK: - ExposureDataOperation

    func execute() -> Observable<LabConfirmationKey> {
        return retrieveStoredKey()
            .flatMap { confirmationKey -> Observable<LabConfirmationKey> in
                if let confirmationKey = confirmationKey, confirmationKey.isValid {
                    return .just(confirmationKey)
                }

                return self.requestNewKey()
                    .flatMap(self.storeReceivedKey(key:))
            }
    }

    private func retrieveStoredKey() -> Observable<LabConfirmationKey?> {
        let key = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.labConfirmationKey)
        return .just(key)
    }

    private func storeReceivedKey(key: LabConfirmationKey) -> Observable<LabConfirmationKey> {
        let observable = Observable<LabConfirmationKey>.create { observer in

            self.storageController.store(object: key,
                                         identifiedBy: ExposureDataStorageKey.labConfirmationKey,
                                         completion: { error in
                                             if error != nil {
                                                 observer.onError(ExposureDataError.internalError)
                                             } else {
                                                 observer.onNext(key)
                                                 observer.onCompleted()
                                             }
                                         })

            return Disposables.create()
        }

        return observable.share()
    }

    private func requestNewKey() -> Observable<LabConfirmationKey> {
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

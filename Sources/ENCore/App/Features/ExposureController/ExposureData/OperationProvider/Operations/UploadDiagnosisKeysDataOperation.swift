/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import RxCombine
import RxSwift

final class UploadDiagnosisKeysDataOperation: ExposureDataOperation, Logging {
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
        let keys = diagnosisKeys

        return networkController
            // execute network request
            .postKeys(keys: keys, labConfirmationKey: labConfirmationKey, padding: padding)
            .mapError { (error: NetworkError) -> ExposureDataError in error.asExposureDataError }
            .catch { error in
                self.scheduleRetryWhenFailed(error: error, diagnosisKeys: self.diagnosisKeys, labConfirmationKey: self.labConfirmationKey)
                    .publisher
                    .assertNoFailure()
                    .setFailureType(to: ExposureDataError.self)
                    .share()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func scheduleRetryWhenFailed(error: ExposureDataError, diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> Observable<()> {

        return .create { [weak self] observer in

            guard let strongSelf = self else {
                observer.onError(ExposureDataError.internalError)
                return Disposables.create()
            }

            let retryRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: labConfirmationKey,
                                                                   diagnosisKeys: diagnosisKeys,
                                                                   expiryDate: labConfirmationKey.expiration)

            strongSelf.logDebug("Saving PendingLabConfirmationUploadRequest: \(retryRequest)")

            strongSelf.storageController.requestExclusiveAccess { storageController in
                var requests = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []

                requests.append(retryRequest)

                storageController.store(object: requests, identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) { _ in
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let diagnosisKeys: [DiagnosisKey]
    private let labConfirmationKey: LabConfirmationKey
    private let padding: Padding
}

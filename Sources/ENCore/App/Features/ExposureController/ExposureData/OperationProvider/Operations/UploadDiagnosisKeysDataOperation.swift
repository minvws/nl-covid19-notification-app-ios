/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift

/// @mockable
protocol UploadDiagnosisKeysDataOperationProtocol {
    func execute() -> Completable
}

final class UploadDiagnosisKeysDataOperation: UploadDiagnosisKeysDataOperationProtocol, Logging {
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

    func execute() -> Completable {

        return networkController
            .postKeys(keys: diagnosisKeys, labConfirmationKey: labConfirmationKey, padding: padding)
            .subscribe(on: MainScheduler.instance)
            .catch { error in

                guard let exposureDataError = (error as? NetworkError)?.asExposureDataError else {
                    throw ExposureDataError.internalError
                }

                return self.scheduleRetryWhenFailed(error: exposureDataError, diagnosisKeys: self.diagnosisKeys, labConfirmationKey: self.labConfirmationKey)
            }
    }

    // MARK: - Private

    private func scheduleRetryWhenFailed(error: ExposureDataError, diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> Completable {

        return .create { [weak self] observer in

            guard let strongSelf = self else {
                observer(.error(ExposureDataError.internalError))
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
                    observer(.completed)
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

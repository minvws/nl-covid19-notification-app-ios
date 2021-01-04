/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import UserNotifications

struct PendingLabConfirmationUploadRequest: Codable, Equatable {
    let labConfirmationKey: LabConfirmationKey
    let diagnosisKeys: [DiagnosisKey]
    var expiryDate: Date
}

protocol ProcessPendingLabConfirmationUploadRequestsDataOperationProtocol {}
final class ProcessPendingLabConfirmationUploadRequestsDataOperation: ProcessPendingLabConfirmationUploadRequestsDataOperationProtocol, Logging {

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         padding: Padding) {
        self.networkController = networkController
        self.storageController = storageController
        self.padding = padding
    }

    // MARK: - ExposureDataOperation

    func execute() -> Observable<()> {
        let allRequests = getPendingRequests()

        logDebug("--- START PROCESSING PENDING UPLOAD REQUESTS ---")
        logDebug("All requests: \(allRequests)")

        let requests = allRequests
            // filter out the expired ones
            .filter { request in request.isExpired == false }
            // upload them and get a stream in return
            .map(self.uploadPendingRequest(_:))

        return Observable.from(requests)
            // execute one at the same time
            .merge(maxConcurrent: 1)
            // filter out the unsuccessful ones
            .filter { _, success in success }
            // ditch the success boolean
            .map { tuple in tuple.0 }
            // convert them into an array
            .toArray()
            // remove the successful ones from storage
            .flatMap { requestArray in
                self.removeSuccessRequestsFromStorage(requestArray)
            }
            .do { [weak self] _ in
                self?.logDebug("--- ENDED PROCESSING PENDING UPLOAD REQUESTS ---")
            } onError: { [weak self] _ in
                self?.logDebug("--- PROCESSING PENDING UPLOAD REQUESTS FAILED ---")
            }
            .asObservable()
            .share()
    }

    // MARK: - Private

    private func getPendingRequests() -> [PendingLabConfirmationUploadRequest] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []
    }

    private func uploadPendingRequest(_ request: PendingLabConfirmationUploadRequest) -> Observable<(PendingLabConfirmationUploadRequest, Bool)> {
        logDebug("Uploading pending request with key: \(request.labConfirmationKey.key)")

        return networkController.postKeys(keys: request.diagnosisKeys,
                                          labConfirmationKey: request.labConfirmationKey,
                                          padding: padding)
            .do(onError: { [weak self] _ in
                self?.logDebug("Request with key: \(request.labConfirmationKey.key) completed")
            }, onCompleted: { [weak self] in
                self?.logDebug("Request with key: \(request.labConfirmationKey.key) failed")
            })
            // map results to include a boolean indicating success
            .map { _ in (request, true) }
            // convert errors into the sample tuple - with succuess = false
            .catchAndReturn((request, false))
    }

    private func removeSuccessRequestsFromStorage(_ requests: [PendingLabConfirmationUploadRequest]) -> Single<()> {
        return .create { (observer) -> Disposable in

            self.storageController.requestExclusiveAccess { storageController in

                // get stored pending requests
                let previousRequests = storageController
                    .retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []

                let requestsToStore = previousRequests.filter { request in
                    // filter out successful or expired requests
                    requests.contains(request) == false && !request.isExpired
                }

                self.logDebug("Storing new pending requests: \(requestsToStore)")

                // store back
                storageController.store(object: requestsToStore, identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) { error in
                    if let error = error {
                        observer(.failure(error))
                    } else {
                        observer(.success(()))
                    }
                }
            }

            return Disposables.create()
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let padding: Padding
}

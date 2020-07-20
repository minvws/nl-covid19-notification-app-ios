/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct PendingLabConfirmationUploadRequest: Codable, Equatable {
    let labConfirmationKey: LabConfirmationKey
    let diagnosisKeys: [DiagnosisKey]
    let expiryDate: Date
}

final class ProcessPendingLabConfirmationUploadRequestsDataOperation: ExposureDataOperation, Logging {

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         padding: Padding) {
        self.networkController = networkController
        self.storageController = storageController
        self.padding = padding
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<(), ExposureDataError> {
        let allRequests = getPendingRequests()

        logDebug("--- START PROCESSING PENDING UPLOAD REQUESTS ---")
        logDebug("All requests: \(allRequests)")

        let requests = allRequests
            // filter out the expired ones
            .filter { $0.isExpired == false }
            // upload them and get a stream in return
            .map(self.uploadPendingRequest(_:))

        let expiredRequests = allRequests.filter { $0.isExpired }

        logDebug("Expired requests: \(expiredRequests)")

        // bundle all streams
        return Publishers.Sequence<[AnyPublisher<(PendingLabConfirmationUploadRequest, Bool), Never>], Never>(sequence: requests)
            // execute one at the same time
            .flatMap(maxPublishers: .max(1)) { $0 }
            // filter out the unsuccessful ones
            .filter { _, success in success }
            // ditch the success boolean
            .map { tuple in tuple.0 }
            // convert them into an array
            .collect()
            // remove the successful ones from storage
            .flatMap {
                self.removeSuccessRequestsFromStorage($0, expiredRequests: expiredRequests)
            }
            // we cannot fail, but error type has to match
            .setFailureType(to: ExposureDataError.self)
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.logDebug("--- ENDED PROCESSING PENDING UPLOAD REQUESTS ---")
                },
                receiveCancel: { [weak self] in
                    self?.logDebug("--- PROCESSING PENDING UPLOAD REQUESTS WAS CANCELLED ---")
            })
            .share()
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func getPendingRequests() -> [PendingLabConfirmationUploadRequest] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []
    }

    private func uploadPendingRequest(_ request: PendingLabConfirmationUploadRequest) -> AnyPublisher<(PendingLabConfirmationUploadRequest, Bool), Never> {
        logDebug("Uploading pending request with key: \(request.labConfirmationKey.key)")

        return networkController.postKeys(keys: request.diagnosisKeys,
                                          labConfirmationKey: request.labConfirmationKey,
                                          padding: padding)
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .finished = completion {
                    self?.logDebug("Request with key: \(request.labConfirmationKey.key) completed")
                } else {
                    self?.logDebug("Request with key: \(request.labConfirmationKey.key) failed")
                }
            })
            // map results to include a boolean indicating success
            .map { _ in (request, true) }
            // convert errors into the sample tuple - with succuess = false
            .catch { _ in Just((request, false)) }
            .eraseToAnyPublisher()
    }

    private func removeSuccessRequestsFromStorage(_ requests: [PendingLabConfirmationUploadRequest],
                                                  expiredRequests: [PendingLabConfirmationUploadRequest]) -> AnyPublisher<(), Never> {
        return Deferred {
            Future { promise in
                self.storageController.requestExclusiveAccess { storageController in
                    // get stored pending requests
                    var requestsToStore = storageController
                        .retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []

                    // filter out successful or expired requests
                    requestsToStore = requestsToStore.filter { request in
                        requests.contains(request) == false && expiredRequests.contains(request) == false
                    }

                    self.logDebug("Storing new pending requests: \(requestsToStore)")

                    // store back
                    storageController.store(object: requestsToStore, identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) { _ in
                        promise(.success(()))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let padding: Padding
}

private extension PendingLabConfirmationUploadRequest {
    var isExpired: Bool {
        return expiryDate < Date()
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import XCTest

final class ProcessPendingLabConfirmationUploadRequestsDataOperationTests: TestCase {
    private var operation: ProcessPendingLabConfirmationUploadRequestsDataOperation!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!

    override func setUp() {
        super.setUp()

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()

        operation = ProcessPendingLabConfirmationUploadRequestsDataOperation(networkController: mockNetworkController,
                                                                             storageController: mockStorageController,
                                                                             padding: Padding(minimumRequestSize: 0, maximumRequestSize: 0))

        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }
    }

    func test_singlePendingRequest_callsPostKeys_andRemovesFromStorageWhenSuccessful() {
        let pendingRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: currentDate().addingTimeInterval(20))

        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([pendingRequest])
        }

        var receivedKeys: [DiagnosisKey]!
        var receivedLabConfirmationKey: LabConfirmationKey!
        mockNetworkController.postKeysHandler = { keys, labConfirmationKey, padding in
            receivedKeys = keys
            receivedLabConfirmationKey = labConfirmationKey

            return .empty()
        }

        var receivedNewPendingRequests: [PendingLabConfirmationUploadRequest]!
        mockStorageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedNewPendingRequests = try! jsonDecoder.decode([PendingLabConfirmationUploadRequest].self, from: data)

            completion(nil)
        }

        XCTAssertEqual(mockStorageController.retrieveDataCallCount, 0)
        XCTAssertEqual(mockNetworkController.postKeysCallCount, 0)
        XCTAssertEqual(mockStorageController.storeCallCount, 0)
        XCTAssertEqual(mockStorageController.requestExclusiveAccessCallCount, 0)

        wait(for: operation)

        XCTAssertEqual(mockNetworkController.postKeysCallCount, 1)
        XCTAssertEqual(mockStorageController.retrieveDataCallCount, 2)
        XCTAssertEqual(mockStorageController.storeCallCount, 1)
        XCTAssertEqual(mockStorageController.requestExclusiveAccessCallCount, 1)

        XCTAssertNotNil(receivedNewPendingRequests)
        XCTAssertEqual(receivedNewPendingRequests.count, 0)
        XCTAssertEqual(receivedLabConfirmationKey, pendingRequest.labConfirmationKey)
        XCTAssertEqual(receivedKeys, pendingRequest.diagnosisKeys)
    }

    func test_multiplePendingOperations_callPostKeysMultipleTimes() {
        let pendingRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: currentDate().addingTimeInterval(20))
        let pendingRequests = [pendingRequest, pendingRequest, pendingRequest]

        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(pendingRequests)
        }

        mockNetworkController.postKeysHandler = { keys, labConfirmationKey, padding in
            .empty()
        }

        mockStorageController.storeHandler = { _, _, completion in completion(nil) }

        XCTAssertEqual(mockNetworkController.postKeysCallCount, 0)

        wait(for: operation)

        XCTAssertEqual(mockNetworkController.postKeysCallCount, 3)
    }

    func test_pendingRequestIsExpired_doesNotCallNetworkAndDoesNotStoreAgain() {
        let expiredRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: currentDate().addingTimeInterval(-1))

        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([expiredRequest])
        }

        var receivedRequests: [PendingLabConfirmationUploadRequest]!
        mockStorageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedRequests = try! jsonDecoder.decode([PendingLabConfirmationUploadRequest].self, from: data)

            completion(nil)
        }

        XCTAssertEqual(mockNetworkController.postKeysCallCount, 0)

        wait(for: operation)

        XCTAssertEqual(mockNetworkController.postKeysCallCount, 0)
        XCTAssertNotNil(receivedRequests)
        XCTAssertEqual(receivedRequests.count, 0)
    }

    func test_failedRequest_isScheduledAgain() {
        let request = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                          diagnosisKeys: createDiagnosisKeys(),
                                                          expiryDate: currentDate().addingTimeInterval(20))

        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([request])
        }

        mockNetworkController.postKeysHandler = { _, _, _ in
            .error(NetworkError.invalidRequest)
        }

        var receivedRequests: [PendingLabConfirmationUploadRequest]!
        mockStorageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedRequests = try! jsonDecoder.decode([PendingLabConfirmationUploadRequest].self, from: data)

            completion(nil)
        }

        wait(for: operation)

        XCTAssertNotNil(receivedRequests)
        XCTAssertEqual(receivedRequests.count, 1)
        XCTAssertEqual(receivedRequests[0], request)
    }

    // MARK: - Private

    private func wait(for operation: ProcessPendingLabConfirmationUploadRequestsDataOperation) {
        let exp = expectation(description: "wait")
        operation.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: 1)
    }

    private func createLabConfirmationKey() -> LabConfirmationKey {
        return LabConfirmationKey(identifier: "test",
                                  bucketIdentifier: Data(),
                                  confirmationKey: Data(),
                                  validUntil: currentDate())
    }

    private func createDiagnosisKeys() -> [DiagnosisKey] {
        return (0 ... 3).map { index in
            return DiagnosisKey(keyData: Data(),
                                rollingPeriod: 23,
                                rollingStartNumber: UInt32(index),
                                transmissionRiskLevel: 3)
        }
    }
}

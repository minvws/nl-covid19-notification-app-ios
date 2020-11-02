/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import ENFoundation
import Foundation
import XCTest

final class ProcessPendingLabConfirmationUploadRequestsDataOperationTests: TestCase {
    private var operation: ProcessPendingLabConfirmationUploadRequestsDataOperation!
    private let networkController = NetworkControllingMock()
    private let storageController = StorageControllingMock()
    private let userNotificationCenter = UserNotificationCenterMock()

    override func setUp() {
        super.setUp()

        operation = ProcessPendingLabConfirmationUploadRequestsDataOperation(networkController: networkController,
                                                                             storageController: storageController,
                                                                             userNotificationCenter: userNotificationCenter,
                                                                             padding: Padding(minimumRequestSize: 0, maximumRequestSize: 0))

        storageController.requestExclusiveAccessHandler = { $0(self.storageController) }
        userNotificationCenter.getAuthorizationStatusHandler = { $0(.authorized) }
    }

    func test_singlePendingRequest_callsPostKeys_andRemovesFromStorageWhenSuccessful() {
        let pendingRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: Date().addingTimeInterval(20))

        storageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([pendingRequest])
        }

        var receivedKeys: [DiagnosisKey]!
        var receivedLabConfirmationKey: LabConfirmationKey!
        networkController.postKeysHandler = { keys, labConfirmationKey, padding in
            receivedKeys = keys
            receivedLabConfirmationKey = labConfirmationKey

            return Just(()).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
        }

        var receivedNewPendingRequests: [PendingLabConfirmationUploadRequest]!
        storageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedNewPendingRequests = try! jsonDecoder.decode([PendingLabConfirmationUploadRequest].self, from: data)

            completion(nil)
        }

        XCTAssertEqual(storageController.retrieveDataCallCount, 0)
        XCTAssertEqual(networkController.postKeysCallCount, 0)
        XCTAssertEqual(storageController.storeCallCount, 0)
        XCTAssertEqual(storageController.requestExclusiveAccessCallCount, 0)

        wait(for: operation)

        XCTAssertEqual(networkController.postKeysCallCount, 1)
        XCTAssertEqual(storageController.retrieveDataCallCount, 2)
        XCTAssertEqual(storageController.storeCallCount, 1)
        XCTAssertEqual(storageController.requestExclusiveAccessCallCount, 1)
        XCTAssertEqual(userNotificationCenter.addCallCount, 0)

        XCTAssertNotNil(receivedNewPendingRequests)
        XCTAssertEqual(receivedNewPendingRequests.count, 0)
        XCTAssertEqual(receivedLabConfirmationKey, pendingRequest.labConfirmationKey)
        XCTAssertEqual(receivedKeys, pendingRequest.diagnosisKeys)
    }

    func test_multiplePendingOperations_callPostKeysMultipleTimes() {
        let pendingRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: Date().addingTimeInterval(20))
        let pendingRequests = [pendingRequest, pendingRequest, pendingRequest]

        storageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(pendingRequests)
        }

        networkController.postKeysHandler = { keys, labConfirmationKey, padding in
            return Just(()).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
        }

        storageController.storeHandler = { _, _, completion in completion(nil) }

        XCTAssertEqual(networkController.postKeysCallCount, 0)

        wait(for: operation)

        XCTAssertEqual(networkController.postKeysCallCount, 3)
        XCTAssertEqual(userNotificationCenter.addCallCount, 0)
    }

    func test_pendingRequestIsExpired_doesNotCallNetworkAndDoesNotStoreAgain() {
        let expiredRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: Date().addingTimeInterval(-1))

        storageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([expiredRequest])
        }

        var receivedRequests: [PendingLabConfirmationUploadRequest]!
        storageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedRequests = try! jsonDecoder.decode([PendingLabConfirmationUploadRequest].self, from: data)

            completion(nil)
        }

        XCTAssertEqual(networkController.postKeysCallCount, 0)

        wait(for: operation)

        XCTAssertEqual(networkController.postKeysCallCount, 0)
        XCTAssertNotNil(receivedRequests)
        XCTAssertEqual(receivedRequests.count, 0)
    }

    func test_pendingRequestIsExpired_notifiesUser() {
        let expiredRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: Date().addingTimeInterval(-1))

        storageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([expiredRequest])
        }

        storageController.storeHandler = { _, _, completion in
            completion(nil)
        }

        wait(for: operation)

        XCTAssertEqual(userNotificationCenter.addCallCount, 1)
    }

    func test_failedRequest_isScheduledAgain() {
        let request = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                          diagnosisKeys: createDiagnosisKeys(),
                                                          expiryDate: Date().addingTimeInterval(20))

        storageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([request])
        }

        networkController.postKeysHandler = { _, _, _ in Fail(error: NetworkError.invalidRequest).eraseToAnyPublisher() }

        var receivedRequests: [PendingLabConfirmationUploadRequest]!
        storageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedRequests = try! jsonDecoder.decode([PendingLabConfirmationUploadRequest].self, from: data)

            completion(nil)
        }

        wait(for: operation)

        XCTAssertNotNil(receivedRequests)
        XCTAssertEqual(receivedRequests.count, 1)
        XCTAssertEqual(receivedRequests[0], request)
    }

    func test_NotScheduledNotification() {
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        XCTAssertNil(operation.triggerIfNeeded())
    }

    func test_ScheduledNotification() {
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593290000) // 27/06/20 20:33
        XCTAssertNotNil(operation.triggerIfNeeded())
    }

    // MARK: - Private

    private func wait(for operation: ProcessPendingLabConfirmationUploadRequestsDataOperation) {
        let exp = expectation(description: "wait")
        operation.execute()
            .sink(receiveCompletion: { _ in exp.fulfill() },
                  receiveValue: { _ in }
            )
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)
    }

    private func createLabConfirmationKey() -> LabConfirmationKey {
        return LabConfirmationKey(identifier: "test",
                                  bucketIdentifier: Data(),
                                  confirmationKey: Data(),
                                  validUntil: Date())
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

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import XCTest

final class UploadDiagnosisKeysDataOperationTests: TestCase {
    private var operation: UploadDiagnosisKeysDataOperation!
    private let networkController = NetworkControllingMock()
    private let storageController = StorageControllingMock()

    override func setUp() {
        super.setUp()

        operation = createOperation(withKeys: createDiagnosisKeys(withHighestRollingStartNumber: 65))
    }

    func test_execute_noPreviousSet_uploadsAll() {
        var receivedKeys: [DiagnosisKey]!

        networkController.postKeysHandler = { keys, confirmationKey, padding in
            receivedKeys = keys

            return Just(())
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }

        let keys = createDiagnosisKeys(withHighestRollingStartNumber: 65)
        operation = createOperation(withKeys: keys)

        XCTAssertEqual(networkController.postKeysCallCount, 0)

        operation.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(networkController.postKeysCallCount, 1)
        XCTAssertNotNil(receivedKeys)
        XCTAssertEqual(keys, receivedKeys)
    }

    func test_execute_stores_uploadedRollingNumbersAfterSuccessfulUpload() {
        networkController.postKeysHandler = { keys, confirmationKey, padding in
            return Just(())
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }

        var receivedData: Data!
        storageController.storeHandler = { data, _, completion in
            receivedData = data
            completion(nil)
        }

        let keys = createDiagnosisKeys(withHighestRollingStartNumber: 65)
        operation = createOperation(withKeys: keys)

        XCTAssertEqual(storageController.storeCallCount, 0)

        operation.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertNotNil(receivedData)
        XCTAssertEqual(storageController.storeCallCount, 1)

        let rollingStartNumbers = try! JSONDecoder().decode([UInt32].self, from: receivedData)
        XCTAssertEqual(rollingStartNumbers.count, 6)
        XCTAssertEqual(rollingStartNumbers, [65, 64, 63, 62, 61, 60])
    }

    func test_execute_readsUploadedRollingNumberAndPendingOperationsAndFiltersOutKeys() {
        var receivedKeys: [DiagnosisKey]!
        networkController.postKeysHandler = { keys, confirmationKey, padding in
            receivedKeys = keys

            return Just(())
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }

        storageController.retrieveDataHandler = { key in
            switch (key as! StoreKey).asString {
            case "uploadedRollingStartNumbers":
                return try! JSONEncoder().encode([UInt32]([62, 64]))
            case "pendingLabUploadRequests":
                let requests = [
                    PendingLabConfirmationUploadRequest(labConfirmationKey: self.createLabConfirmationKey(),
                                                        diagnosisKeys: [
                                                            DiagnosisKey(keyData: Data(),
                                                                         rollingPeriod: 0,
                                                                         rollingStartNumber: 65,
                                                                         transmissionRiskLevel: 0)
                                                        ],
                                                        expiryDate: Date().addingTimeInterval(60))
                ]

                return try! JSONEncoder().encode(requests)
            default:
                return nil
            }
        }

        let keys = createDiagnosisKeys(withHighestRollingStartNumber: 67) // creates 5 keys, from 63-67
        let expectedKeys = keys.filter { $0.rollingStartNumber != 62 && $0.rollingStartNumber != 64 && $0.rollingStartNumber != 65 }

        var receivedData: Data!
        storageController.storeHandler = { data, _, completion in
            receivedData = data
            completion(nil)
        }

        operation = createOperation(withKeys: keys)

        XCTAssertEqual(storageController.storeCallCount, 0)
        XCTAssertEqual(storageController.retrieveDataCallCount, 0)

        operation.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertNotNil(receivedKeys)
        XCTAssertEqual(receivedKeys, expectedKeys)
        XCTAssertEqual(storageController.retrieveDataCallCount, 2) // once for pending operations, once for rollingStartNumbers
        XCTAssertEqual(storageController.storeCallCount, 1)

        // new stored rolling start numbers should be
        let rollingStartNumbers = try! JSONDecoder().decode([UInt32].self, from: receivedData)
        XCTAssertEqual(rollingStartNumbers, [67, 66, 63])
    }

    func test_error_schedulesRetryRequest() {
        let expiryDate = Date().addingTimeInterval(60)
        let alreadyPendingRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(validUntil: expiryDate),
                                                                        diagnosisKeys: [],
                                                                        expiryDate: expiryDate)

        operation = createOperation(withKeys: createDiagnosisKeys(withHighestRollingStartNumber: 65), expiryDate: expiryDate)

        networkController.postKeysHandler = { keys, confirmationKey, padding in
            return Fail(error: NetworkError.invalidRequest).eraseToAnyPublisher()
        }

        storageController.requestExclusiveAccessHandler = { $0(self.storageController) }

        storageController.retrieveDataHandler = { key in
            if key is CodableStorageKey<Int32> {
                let bytes: [UInt8] = [0, 0]
                return Data(bytes)
            }

            if key is CodableStorageKey<[PendingLabConfirmationUploadRequest]> {
                let encoder = JSONEncoder()
                return try! encoder.encode([alreadyPendingRequest])
            }

            return nil
        }

        var receivedPendingRequests: [PendingLabConfirmationUploadRequest]!
        storageController.storeHandler = { data, _, _ in
            let decoder = JSONDecoder()
            receivedPendingRequests = try! decoder.decode([PendingLabConfirmationUploadRequest].self, from: data)
        }

        XCTAssertEqual(storageController.retrieveDataCallCount, 0)
        XCTAssertEqual(storageController.storeCallCount, 0)

        operation.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(storageController.storeCallCount, 1)
        XCTAssertEqual(storageController.retrieveDataCallCount, 3)
        XCTAssertEqual(receivedPendingRequests.count, 2)
        XCTAssertEqual(receivedPendingRequests[0], alreadyPendingRequest)
        XCTAssertEqual(receivedPendingRequests[1].diagnosisKeys, createDiagnosisKeys(withHighestRollingStartNumber: 65))
        XCTAssertEqual(receivedPendingRequests[1].expiryDate, expiryDate)
    }

    func test_noKeys_doesNotReachOutToNetwork() {
        operation = createOperation(withKeys: [])

        XCTAssertEqual(networkController.postKeysCallCount, 0)

        operation.execute()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(networkController.postKeysCallCount, 0)
    }

    // MARK: - Private

    private func createDiagnosisKeys(withHighestRollingStartNumber highestRollingStartNumber: Int32) -> [DiagnosisKey] {
        let numberOfKeys: Int32 = 5

        return (0 ... numberOfKeys).map { i -> DiagnosisKey in
            let rollingStartNumber = max(highestRollingStartNumber, numberOfKeys) - i

            return DiagnosisKey(keyData: Data(),
                                rollingPeriod: 0,
                                rollingStartNumber: UInt32(rollingStartNumber),
                                transmissionRiskLevel: 23)
        }
    }

    private func createOperation(withKeys keys: [DiagnosisKey], expiryDate: Date = Date()) -> UploadDiagnosisKeysDataOperation {
        return UploadDiagnosisKeysDataOperation(networkController: networkController,
                                                storageController: storageController,
                                                diagnosisKeys: keys,
                                                labConfirmationKey: createLabConfirmationKey(validUntil: expiryDate),
                                                padding: Padding(minimumRequestSize: 0, maximumRequestSize: 0))
    }

    private func createLabConfirmationKey(validUntil: Date = Date()) -> LabConfirmationKey {
        LabConfirmationKey(identifier: "test",
                           bucketIdentifier: "bucket".data(using: .utf8)!,
                           confirmationKey: Data(),
                           validUntil: validUntil)
    }
}

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

final class UploadDiagnosisKeysDataOperationTests: TestCase {
    private var operation: UploadDiagnosisKeysDataOperation!
    private let networkController = NetworkControllingMock()
    private let storageController = StorageControllingMock()

    override func setUp() {
        super.setUp()

        storageController.requestExclusiveAccessHandler = { block in block(self.storageController) }

        operation = createOperation(withKeys: createDiagnosisKeys(withHighestRollingStartNumber: 65))
    }

    func test_execute_noPreviousSet_uploadsAll() {
        var receivedKeys: [DiagnosisKey]!

        networkController.postKeysHandler = { keys, confirmationKey, padding in
            receivedKeys = keys
            return .empty()
        }

        let keys = createDiagnosisKeys(withHighestRollingStartNumber: 65)
        operation = createOperation(withKeys: keys)

        XCTAssertEqual(networkController.postKeysCallCount, 0)

        operation.execute()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(networkController.postKeysCallCount, 1)
        XCTAssertNotNil(receivedKeys)
        XCTAssertEqual(keys, receivedKeys)
    }

    func test_error_schedulesRetryRequest() {
        let expiryDate = currentDate().addingTimeInterval(60)
        let alreadyPendingRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(validUntil: expiryDate),
                                                                        diagnosisKeys: [],
                                                                        expiryDate: expiryDate)

        operation = createOperation(withKeys: createDiagnosisKeys(withHighestRollingStartNumber: 65), expiryDate: expiryDate)

        networkController.postKeysHandler = { keys, confirmationKey, padding in
            .error(NetworkError.invalidRequest)
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
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(storageController.storeCallCount, 1)
        XCTAssertEqual(storageController.retrieveDataCallCount, 1)
        XCTAssertEqual(receivedPendingRequests.count, 2)
        XCTAssertEqual(receivedPendingRequests[0], alreadyPendingRequest)
        XCTAssertEqual(receivedPendingRequests[1].diagnosisKeys, createDiagnosisKeys(withHighestRollingStartNumber: 65))
        XCTAssertEqual(receivedPendingRequests[1].expiryDate, expiryDate)
    }

    func test_noKeys_doesReachOutToNetwork() {

        networkController.postKeysHandler = { keys, confirmationKey, padding in
            .empty()
        }

        operation = createOperation(withKeys: [])

        XCTAssertEqual(networkController.postKeysCallCount, 0)

        operation.execute()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(networkController.postKeysCallCount, 1)
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

    private func createOperation(withKeys keys: [DiagnosisKey], expiryDate: Date = currentDate()) -> UploadDiagnosisKeysDataOperation {
        return UploadDiagnosisKeysDataOperation(networkController: networkController,
                                                storageController: storageController,
                                                diagnosisKeys: keys,
                                                labConfirmationKey: createLabConfirmationKey(validUntil: expiryDate),
                                                padding: Padding(minimumRequestSize: 0, maximumRequestSize: 0))
    }

    private func createLabConfirmationKey(validUntil: Date = currentDate()) -> LabConfirmationKey {
        LabConfirmationKey(identifier: "test",
                           bucketIdentifier: "bucket".data(using: .utf8)!,
                           confirmationKey: Data(),
                           validUntil: validUntil)
    }
}

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

        networkController.postKeysHandler = { keys, confirmationKey in
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

    func test_execute_stores_highestRollingNumberAfterSuccessfulUpload() {
        networkController.postKeysHandler = { keys, confirmationKey in
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

        let bytes = [UInt8](receivedData)
        XCTAssertEqual(bytes[0], 54)
        XCTAssertEqual(bytes[1], 53)
    }

    func test_execute_readsHighestRollingNumberAndFiltersOutKeysBelowThat() {
        var receivedKeys: [DiagnosisKey]!
        networkController.postKeysHandler = { keys, confirmationKey in
            receivedKeys = keys

            return Just(())
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }

        storageController.retrieveDataHandler = { _ in
            let bytes: [UInt8] = [54, 53] // Int32(65)

            return Data(bytes)
        }

        let keys = createDiagnosisKeys(withHighestRollingStartNumber: 67) // creates 5 keys, from 63-67
        let expectedKeys = keys.filter { $0.rollingStartNumber > 65 }

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
        XCTAssertEqual(storageController.retrieveDataCallCount, 1)
        XCTAssertEqual(storageController.storeCallCount, 1)

        // new number should be 67
        let bytes = [UInt8](receivedData)
        XCTAssertEqual(bytes[0], 54)
        XCTAssertEqual(bytes[1], 55)
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

    private func createOperation(withKeys keys: [DiagnosisKey]) -> UploadDiagnosisKeysDataOperation {
        let labConfirmationKey = LabConfirmationKey(identifier: "test",
                                                    bucketIdentifier: "bucket".data(using: .utf8)!,
                                                    confirmationKey: Data(),
                                                    validUntil: Date())

        return UploadDiagnosisKeysDataOperation(networkController: networkController,
                                                storageController: storageController,
                                                diagnosisKeys: keys,
                                                labConfirmationKey: labConfirmationKey)
    }
}

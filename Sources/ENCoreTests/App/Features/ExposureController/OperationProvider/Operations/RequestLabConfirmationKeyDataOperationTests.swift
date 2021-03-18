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

final class RequestLabConfirmationKeyDataOperationTests: TestCase {
    private var operation: RequestLabConfirmationKeyDataOperation!
    private let networkController = NetworkControllingMock()
    private let storageController = StorageControllingMock()
    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()

        operation = RequestLabConfirmationKeyDataOperation(networkController: networkController,
                                                           storageController: storageController,
                                                           padding: Padding(minimumRequestSize: 0,
                                                                            maximumRequestSize: 0))
    }

    func test_execute_noPreviousKey() {
        storageController.retrieveDataHandler = { _ in
            return nil
        }
        storageController.storeHandler = { _, _, completion in
            completion(nil)
        }

        networkController.requestLabConfirmationKeyHandler = { _ in
            let labConfirmationKey = LabConfirmationKey(identifier: "id",
                                                        bucketIdentifier: Data(),
                                                        confirmationKey: Data(),
                                                        validUntil: currentDate())
            return .just(labConfirmationKey)
        }

        XCTAssertEqual(storageController.retrieveDataCallCount, 0)
        XCTAssertEqual(storageController.storeCallCount, 0)
        XCTAssertEqual(networkController.requestLabConfirmationKeyCallCount, 0)

        var receivedLabConfirmationKey: LabConfirmationKey!
        operation
            .execute()
            .subscribe(onSuccess: { labConfirmationKey in
                receivedLabConfirmationKey = labConfirmationKey
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(storageController.retrieveDataCallCount, 1)
        XCTAssertEqual(storageController.storeCallCount, 1)
        XCTAssertEqual(networkController.requestLabConfirmationKeyCallCount, 1)
        XCTAssertNotNil(receivedLabConfirmationKey)
    }

    func test_execute_validPreviousKey_noStoreAndNetworkCalls() {
        storageController.retrieveDataHandler = { _ in
            let key = LabConfirmationKey(identifier: "id",
                                         bucketIdentifier: Data(),
                                         confirmationKey: Data(),
                                         validUntil: Date(timeIntervalSinceNow: 20))

            return try! JSONEncoder().encode(key)
        }

        XCTAssertEqual(storageController.retrieveDataCallCount, 0)
        XCTAssertEqual(storageController.storeCallCount, 0)
        XCTAssertEqual(networkController.requestLabConfirmationKeyCallCount, 0)

        var receivedLabConfirmationKey: LabConfirmationKey!
        operation
            .execute()
            .subscribe(onSuccess: { labConfirmationKey in
                receivedLabConfirmationKey = labConfirmationKey
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(storageController.retrieveDataCallCount, 1)
        XCTAssertEqual(storageController.storeCallCount, 0)
        XCTAssertEqual(networkController.requestLabConfirmationKeyCallCount, 0)
        XCTAssertNotNil(receivedLabConfirmationKey)
    }

    func test_execute_previousButExpiredKey_downloadsAndStoresNewKey() {
        storageController.retrieveDataHandler = { _ in
            let key = LabConfirmationKey(identifier: "id",
                                         bucketIdentifier: Data(),
                                         confirmationKey: Data(),
                                         validUntil: Date(timeIntervalSinceNow: -1))

            return try! JSONEncoder().encode(key)
        }
        storageController.storeHandler = { _, _, completion in
            completion(nil)
        }

        networkController.requestLabConfirmationKeyHandler = { _ in
            let labConfirmationKey = LabConfirmationKey(identifier: "id",
                                                        bucketIdentifier: Data(),
                                                        confirmationKey: Data(),
                                                        validUntil: currentDate())
            return .just(labConfirmationKey)
        }

        XCTAssertEqual(storageController.retrieveDataCallCount, 0)
        XCTAssertEqual(storageController.storeCallCount, 0)
        XCTAssertEqual(networkController.requestLabConfirmationKeyCallCount, 0)

        var receivedLabConfirmationKey: LabConfirmationKey!
        operation
            .execute()
            .subscribe(onSuccess: { labConfirmationKey in
                receivedLabConfirmationKey = labConfirmationKey
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(storageController.retrieveDataCallCount, 1)
        XCTAssertEqual(storageController.storeCallCount, 1)
        XCTAssertEqual(networkController.requestLabConfirmationKeyCallCount, 1)
        XCTAssertNotNil(receivedLabConfirmationKey)
    }
}

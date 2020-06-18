/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import EN
import Foundation
import XCTest

final class RequestLabConfirmationKeyDataOperationTests: XCTestCase {
    private var operation: RequestLabConfirmationKeyDataOperation!
    private let networkController = NetworkControllingMock()
    private let storageController = StorageControllingMock()
    private var disposeBag = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        operation = RequestLabConfirmationKeyDataOperation(networkController: networkController,
                                                           storageController: storageController)
    }

    override func tearDown() {
        super.tearDown()

        disposeBag.forEach { $0.cancel() }
    }

    func test_execute_noPreviousKey() {
        storageController.retrieveDataHandler = { _ in
            return nil
        }
        storageController.storeHandler = { _, _, completion in
            completion(nil)
        }

        networkController.requestLabConfirmationKeyHandler = {
            let labConfirmationKey = LabConfirmationKey(identifier: "id",
                                                        bucketIdentifier: Data(),
                                                        confirmationKey: Data(),
                                                        validUntil: Date())
            return Just(labConfirmationKey)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }

        XCTAssertEqual(storageController.retrieveDataCallCount, 0)
        XCTAssertEqual(storageController.storeCallCount, 0)
        XCTAssertEqual(networkController.requestLabConfirmationKeyCallCount, 0)

        var receivedLabConfirmationKey: LabConfirmationKey!
        operation
            .execute()
            .sink { labConfirmationKey in
                receivedLabConfirmationKey = labConfirmationKey
            }
            .store(in: &disposeBag)

        XCTAssertEqual(storageController.retrieveDataCallCount, 1)
        XCTAssertEqual(storageController.storeCallCount, 1)
        XCTAssertEqual(networkController.requestLabConfirmationKeyCallCount, 1)
        XCTAssertNotNil(receivedLabConfirmationKey)
    }
}

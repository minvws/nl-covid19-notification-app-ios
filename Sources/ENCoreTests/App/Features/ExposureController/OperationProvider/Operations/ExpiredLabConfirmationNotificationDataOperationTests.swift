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

final class ExpiredLabConfirmationNotificationDataOperationTests: TestCase {
    private var operation: ExpiredLabConfirmationNotificationDataOperation!
    private var mockStorageController: StorageControllingMock!
    private var mockUserNotificationController: UserNotificationControllingMock!
    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()

        mockStorageController = StorageControllingMock()
        mockUserNotificationController = UserNotificationControllingMock()

        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }
        mockUserNotificationController.getAuthorizationStatusHandler = { $0(.authorized) }

        operation = ExpiredLabConfirmationNotificationDataOperation(storageController: mockStorageController,
                                                                    userNotificationController: mockUserNotificationController)
    }

    func test_pendingRequestIsExpired_doesNotCallNetworkAndDoesNotStoreAgain() {
        let expiredRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: Date().addingTimeInterval(-1))

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

        wait(for: operation)

        XCTAssertNotNil(receivedRequests)
        XCTAssertEqual(receivedRequests.count, 0)
    }

    func test_pendingRequestIsExpired_notifiesUser() {
        let expiredRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: Date().addingTimeInterval(-1))

        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([expiredRequest])
        }

        mockStorageController.storeHandler = { _, _, completion in
            completion(nil)
        }

        wait(for: operation)

        XCTAssertEqual(mockUserNotificationController.displayUploadFailedNotificationCallCount, 1)
    }

    // MARK: - Private

    private func wait(for operation: ExpiredLabConfirmationNotificationDataOperation) {
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

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
    private var mockUserNotificationCenter: UserNotificationCenterMock!
    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()

        mockStorageController = StorageControllingMock()
        mockUserNotificationCenter = UserNotificationCenterMock()

        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }
        mockUserNotificationCenter.getAuthorizationStatusHandler = { $0(.authorized) }

        operation = ExpiredLabConfirmationNotificationDataOperation(storageController: mockStorageController,
                                                                    userNotificationCenter: mockUserNotificationCenter)
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

        wait(for: operation)

        XCTAssertNotNil(receivedRequests)
        XCTAssertEqual(receivedRequests.count, 0)
    }

    func test_pendingRequestIsExpired_notifiesUser() {
        let expiredRequest = PendingLabConfirmationUploadRequest(labConfirmationKey: createLabConfirmationKey(),
                                                                 diagnosisKeys: createDiagnosisKeys(),
                                                                 expiryDate: currentDate().addingTimeInterval(-1))

        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([expiredRequest])
        }

        mockStorageController.storeHandler = { _, _, completion in
            completion(nil)
        }

        wait(for: operation)

        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
    }

    func test_NotScheduledNotification() {
        let date = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        DateTimeTestingOverrides.overriddenCurrentDate = date

        XCTAssertEqual(date, currentDate())
        XCTAssertNil(operation.getCalendarTriggerForGGDOpeningHourIfNeeded())
    }

    func test_ScheduledNotification() {
        let date = Date(timeIntervalSince1970: 1593311000) // 28/06/20 02:23
        DateTimeTestingOverrides.overriddenCurrentDate = date

        let trigger = operation.getCalendarTriggerForGGDOpeningHourIfNeeded()

        XCTAssertEqual(date, currentDate())
        XCTAssertNotNil(trigger)

        /// GGD working hours
        XCTAssertEqual(trigger?.dateComponents.hour, 8)
        XCTAssertEqual(trigger?.dateComponents.minute, 0)
        XCTAssertEqual(trigger?.dateComponents.timeZone, TimeZone(identifier: "Europe/Amsterdam"))
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

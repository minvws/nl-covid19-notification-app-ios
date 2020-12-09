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

class ProcessExposureKeySetsDataOperationTests: TestCase {

    private var sut: ProcessExposureKeySetsDataOperation!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!
    private var mockExposureManager: ExposureManagingMock!
    private var mockExposureKeySetsStorageUrl: URL!
    private var mockExposureConfiguration: ExposureConfigurationMock!
    private var mockUserNotificationCenter: UserNotificationCenterMock!
    private var mockApplication: ApplicationControllingMock!
    private var mockFileManager: FileManagingMock!
    private var mockEnvironmentController: EnvironmentControllingMock!

    override func setUpWithError() throws {

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()
        mockExposureManager = ExposureManagingMock()
        mockExposureKeySetsStorageUrl = URL(string: "http://someurl.com")!
        mockExposureConfiguration = ExposureConfigurationMock()
        mockUserNotificationCenter = UserNotificationCenterMock()
        mockApplication = ApplicationControllingMock()
        mockFileManager = FileManagingMock()
        mockEnvironmentController = EnvironmentControllingMock()

        // Default handlers
        mockEnvironmentController.isiOS136orHigher = true
        mockUserNotificationCenter.getAuthorizationStatusHandler = { $0(.authorized) }
        mockUserNotificationCenter.addHandler = { $1?(nil) }
        mockExposureManager.detectExposuresHandler = { _, _, completion in
            completion(.success(ExposureDetectionSummaryMock()))
        }
        mockFileManager.fileExistsHandler = { _, _ in true }
        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }
        mockStorageController.storeHandler = { object, identifiedBy, completion in
            completion(nil)
        }

        sut = ProcessExposureKeySetsDataOperation(
            networkController: mockNetworkController,
            storageController: mockStorageController,
            exposureManager: mockExposureManager,
            exposureKeySetsStorageUrl: mockExposureKeySetsStorageUrl,
            configuration: mockExposureConfiguration,
            userNotificationCenter: mockUserNotificationCenter,
            application: mockApplication,
            fileManager: mockFileManager,
            environmentController: mockEnvironmentController
        )
    }

    func test_shouldRetrieveStoredKeySetHolders() {

        let keySetExpectation = expectation(description: "keySetHoldersRequested")

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString {
                keySetExpectation.fulfill()
                return try! JSONEncoder().encode([self.dummyKeySetHolder])
            }

            return nil
        }

        _ = sut.execute()

        XCTAssertTrue(mockStorageController.retrieveDataArgValues.first is CodableStorageKey<[ExposureKeySetHolder]>)
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // If the number of background calls has not reached the limit, a detection call should be made
    func test_shouldDetectExposuresIfBackgroundCallsAvailable() {

        mockApplication.isInBackground = true
        let exposureApiBackgroundCallDates = Array(repeating: Date(), count: 5)

        let exp = expectation(description: "detectExposuresExpectation")

        mockStorage(storedKeySetHolders: [dummyKeySetHolder], exposureApiBackgroundCallDates: exposureApiBackgroundCallDates)

        sut.execute()
            .assertNoFailure()
            .sink { _ in
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 1)
        XCTAssertEqual(mockExposureManager.detectExposuresArgValues.first?.1.first?.absoluteString, "http://someurl.com/signatureFilename")
        XCTAssertEqual(mockExposureManager.detectExposuresArgValues.first?.1.last?.absoluteString, "http://someurl.com/binaryFilename")
    }

    // If the number of background calls has reached the limit, no calls should be allowed anymore
    func test_shouldNotDetectExposuresIfBackgroundCallLimitReached() {

        mockApplication.isInBackground = true
        let exposureApiBackgroundCallDates = Array(repeating: Date(), count: 6)

        let exp = expectation(description: "detectExposuresExpectation")

        mockStorage(storedKeySetHolders: [dummyKeySetHolder], exposureApiBackgroundCallDates: exposureApiBackgroundCallDates)

        sut.execute()
            .assertNoFailure()
            .sink { _ in
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 0)
    }

    // If the number of foreground calls has not reached the limit, a detection call should be made
    func test_shouldDetectExposuresIfForegroundCallsAvailable() {

        mockApplication.isInBackground = false
        let exposureApiForegroundCallDates = Array(repeating: Date(), count: 8)

        let exp = expectation(description: "detectExposuresExpectation")

        mockStorage(storedKeySetHolders: [dummyKeySetHolder], exposureApiCallDates: exposureApiForegroundCallDates)

        sut.execute()
            .assertNoFailure()
            .sink { _ in
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 1)
        XCTAssertEqual(mockExposureManager.detectExposuresArgValues.first?.1.first?.absoluteString, "http://someurl.com/signatureFilename")
        XCTAssertEqual(mockExposureManager.detectExposuresArgValues.first?.1.last?.absoluteString, "http://someurl.com/binaryFilename")
    }

    // If the number of foreground calls has reached the limit, no calls should be allowed anymore
    func test_shouldNotDetectExposuresIfForegroundCallLimitReached() {

        mockApplication.isInBackground = false
        let exposureApiForegroundCallDates = Array(repeating: Date(), count: 9)

        let exp = expectation(description: "detectExposuresExpectation")

        mockStorage(storedKeySetHolders: [dummyKeySetHolder], exposureApiCallDates: exposureApiForegroundCallDates)

        sut.execute()
            .assertNoFailure()
            .sink { _ in
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 0)
    }

    // If the combined call count for foreground and background detection is over the maximum, no calls should be allowed anymore
    func test_shouldNotDetectExposuresIfCombinedCallLimitReached() {

        mockApplication.isInBackground = true
        let exposureApiForegroundCallDates = Array(repeating: Date(), count: 20)
        let exposureApiBackgroundCallDates = Array(repeating: Date(), count: 2)

        let exp = expectation(description: "detectExposuresExpectation")

        mockStorage(storedKeySetHolders: [dummyKeySetHolder], exposureApiBackgroundCallDates: exposureApiBackgroundCallDates, exposureApiCallDates: exposureApiForegroundCallDates)

        sut.execute()
            .assertNoFailure()
            .sink { _ in
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 0)
    }

    private var dummyKeySetHolder: ExposureKeySetHolder {
        ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: Date())
    }

    private func mockStorage(storedKeySetHolders: [ExposureKeySetHolder] = [],
                             exposureApiBackgroundCallDates: [Date] = [],
                             exposureApiCallDates: [Date] = [],
                             lastExposureProcessingDate: Date? = nil) {

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString {
                return try! JSONEncoder().encode(storedKeySetHolders)

            } else if (key as? CodableStorageKey<[Date]>)?.asString == ExposureDataStorageKey.exposureApiBackgroundCallDates.asString {
                return try! JSONEncoder().encode(exposureApiBackgroundCallDates)

            } else if (key as? CodableStorageKey<[Date]>)?.asString == ExposureDataStorageKey.exposureApiCallDates.asString {
                return try! JSONEncoder().encode(exposureApiCallDates)

            } else if (key as? CodableStorageKey<Date>)?.asString == ExposureDataStorageKey.lastExposureProcessingDate.asString {
                return try! JSONEncoder().encode(lastExposureProcessingDate)
            }

            return nil
        }
    }
}

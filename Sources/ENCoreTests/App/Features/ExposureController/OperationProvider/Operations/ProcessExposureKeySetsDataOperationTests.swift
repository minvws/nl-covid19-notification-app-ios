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

class ProcessExposureKeySetsDataOperationTests: XCTestCase {

    private var sut: ProcessExposureKeySetsDataOperation!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!
    private var mockExposureManager: ExposureManagingMock!
    private var mockExposureKeySetsStorageUrl: URL!
    private var mockExposureConfiguration: ExposureConfigurationMock!
    private var mockUserNotificationCenter: UserNotificationCenterMock!
    private var mockApplication: ApplicationControllingMock!
    private var mockFileManager: FileManagingMock!

    override func setUpWithError() throws {

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()
        mockExposureManager = ExposureManagingMock()
        mockExposureKeySetsStorageUrl = URL(string: "http://someurl.com")!
        mockExposureConfiguration = ExposureConfigurationMock()
        mockUserNotificationCenter = UserNotificationCenterMock()
        mockApplication = ApplicationControllingMock()
        mockFileManager = FileManagingMock()

        sut = ProcessExposureKeySetsDataOperation(
            networkController: mockNetworkController,
            storageController: mockStorageController,
            exposureManager: mockExposureManager,
            exposureKeySetsStorageUrl: mockExposureKeySetsStorageUrl,
            configuration: mockExposureConfiguration,
            userNotificationCenter: mockUserNotificationCenter,
            application: mockApplication,
            fileManager: mockFileManager
        )
    }

    func test_shouldRetrieveStoredKeySetHolders() throws {

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

    func test_shouldDetectExposuresIfBackgroundCallsAvailable() throws {

        mockApplication.isInBackground = true

        let detectExposuresExpectation = expectation(description: "detectExposuresExpectation")

        mockExposureManager.detectExposuresHandler = { _, _, _ in
            detectExposuresExpectation.fulfill()
        }

        mockFileManager.fileExistsHandler = { _, _ in
            return true
        }

        mockStorageController.requestExclusiveAccessHandler = { work in
            work(self.mockStorageController)
        }

        mockStorageController.storeHandler = { object, identifiedBy, completion in
            completion(nil)
        }

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString {
                return try! JSONEncoder().encode([self.dummyKeySetHolder])
            } else if (key as? CodableStorageKey<[Date]>)?.asString == ExposureDataStorageKey.exposureApiBackgroundCallDates.asString {
                let callDates = Array(repeating: Date(), count: 5)
                return try! JSONEncoder().encode(callDates)
            } else if (key as? StorageKey)?.asString == ExposureDataStorageKey.exposureApiCallDates.asString {
                return try! JSONEncoder().encode([Date]())
            } else if (key as? CodableStorageKey<Date>)?.asString == ExposureDataStorageKey.lastExposureProcessingDate.asString {
                return try! JSONEncoder().encode([Date]())
            }

            return nil
        }

        _ = sut.execute()

        XCTAssertTrue(mockStorageController.retrieveDataArgValues.first is CodableStorageKey<[ExposureKeySetHolder]>)
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 1)
    }

    private var dummyKeySetHolder: ExposureKeySetHolder {
        ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: Date())
    }
}

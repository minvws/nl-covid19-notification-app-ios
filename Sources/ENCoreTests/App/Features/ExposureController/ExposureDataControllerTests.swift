/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import RxSwift
import XCTest

final class ExposureDataControllerTests: TestCase {

    func test_firstRun_erasesStorage() {

        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()

        var removedKeys: [StoreKey] = []
        mockStorageController.removeDataHandler = { key, _ in
            removedKeys.append(key as! StoreKey)
        }

        var receivedKey: StoreKey!
        var receivedData: Data!
        mockStorageController.storeHandler = { data, key, _ in
            receivedKey = key as? StoreKey
            receivedData = data
        }

        _ = ExposureDataController(operationProvider: mockOperationProvider,
                                   storageController: mockStorageController,
                                   environmentController: mockEnvironmentController)

        XCTAssertEqual(mockStorageController.removeDataCallCount, 3)
        XCTAssertEqual(mockStorageController.storeCallCount, 1)

        let removedKeysStrings = removedKeys.map { $0.asString }
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.labConfirmationKey.asString))
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.lastExposureReport.asString))
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.pendingLabUploadRequests.asString))

        XCTAssertEqual(receivedKey.asString, ExposureDataStorageKey.firstRunIdentifier.asString)
        XCTAssertEqual(receivedData, Data([116, 114, 117, 101])) // true
    }

    func test_update_erasesStoredManifest() {

        let removedManifestExpectation = expectation(description: "Removed Manifest")

        // Creating controller within this test to test initialisation code
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()

        mockEnvironmentController.appVersion = "2.0.0"

        mockStorageController.retrieveDataHandler = { key in
            // mock the last run app version
            if (key as? CodableStorageKey<String>)?.asString == ExposureDataStorageKey.lastRanAppVersion.asString {
                return try! JSONEncoder().encode("1.0.0")
            }

            // Make sure this is not the first run of the app
            if (key as? CodableStorageKey<Bool>)?.asString == ExposureDataStorageKey.firstRunIdentifier.asString {
                return try! JSONEncoder().encode(false)
            }

            return nil
        }

        mockStorageController.removeDataHandler = { key, _ in
            if (key as? CodableStorageKey<ApplicationManifest>)?.asString == ExposureDataStorageKey.appManifest.asString {
                removedManifestExpectation.fulfill()
            }
        }

        _ = ExposureDataController(operationProvider: mockOperationProvider,
                                   storageController: mockStorageController,
                                   environmentController: mockEnvironmentController)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_subsequentRun_doesNotEraseStorage() {}

    // MARK: - requestTreatmentPerspective

    func test_requestTreatmentPerspective_shouldRequestApplicationManifest() {
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController)

        let streamExpectation = expectation(description: "stream")

        let manifestOperationCalledExpectation = expectation(description: "manifestOperationCalled")
        let manifestOperationMock = RequestAppManifestDataOperationProtocolMock()
        manifestOperationMock.executeHandler = {
            manifestOperationCalledExpectation.fulfill()
            return .just(.testData())
        }
        mockOperationProvider.requestManifestOperation = manifestOperationMock

        let treatmentPerspectiveOperationCalled = expectation(description: "treatmentPerspectiveOperationCalled")
        let treatmentPerspectiveOperationMock = RequestTreatmentPerspectiveDataOperationProtocolMock()
        treatmentPerspectiveOperationMock.executeHandler = {
            treatmentPerspectiveOperationCalled.fulfill()
            return .just(TreatmentPerspective.testData())
        }
        mockOperationProvider.requestTreatmentPerspectiveDataOperation = treatmentPerspectiveOperationMock

        sut.requestTreatmentPerspective()
            .sink(receiveCompletion: { _ in
                streamExpectation.fulfill()
            }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(manifestOperationMock.executeCallCount, 1)
    }
}

private extension TreatmentPerspective {
    static func testData(manifestRefreshFrequency: Int = 3600) -> TreatmentPerspective {
        TreatmentPerspective(resources: ["nl": ["key": "value"]], guidance: .init(quarantineDays: 2, layout: []))
    }
}

private extension ApplicationManifest {
    static func testData(creationDate: Date = Date(), appConfigurationIdentifier: String = "appConfigurationIdentifier") -> ApplicationManifest {
        ApplicationManifest(exposureKeySetsIdentifiers: [], riskCalculationParametersIdentifier: "riskCalculationParametersIdentifier", appConfigurationIdentifier: appConfigurationIdentifier, creationDate: creationDate, resourceBundle: "resourceBundle")
    }
}

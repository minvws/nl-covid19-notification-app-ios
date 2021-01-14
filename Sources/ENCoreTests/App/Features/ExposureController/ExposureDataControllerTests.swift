/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import RxSwift
import XCTest

final class ExposureDataControllerTests: TestCase {

    private var disposeBag = DisposeBag()

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
        mockManifestOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: manifestOperationCalledExpectation)

        let treatmentPerspectiveOperationCalled = expectation(description: "treatmentPerspectiveOperationCalled")
        let treatmentPerspectiveOperationMock = RequestTreatmentPerspectiveDataOperationProtocolMock()
        treatmentPerspectiveOperationMock.executeHandler = {
            treatmentPerspectiveOperationCalled.fulfill()
            return .empty()
        }
        mockOperationProvider.requestTreatmentPerspectiveDataOperation = treatmentPerspectiveOperationMock

        sut.updateTreatmentPerspective()
            .subscribe(onCompleted: {
                streamExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - upload

    func test_upload_shouldRequestApplicationManifestAndAppConfiguration() {
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController)

        let streamExpectation = expectation(description: "stream")

        let manifestOperationCalledExpectation = expectation(description: "manifestOperationCalled")
        mockManifestOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: manifestOperationCalledExpectation)

        let configurationOperationCalledExpectation = expectation(description: "configurationOperationCalled")
        mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: configurationOperationCalledExpectation)

        let uploadCalledExpectation = expectation(description: "uploadCalled")
        let uploadOperationMock = UploadDiagnosisKeysDataOperationProtocolMock()
        uploadOperationMock.executeHandler = {
            uploadCalledExpectation.fulfill()
            return .empty()
        }

        mockOperationProvider.uploadDiagnosisKeysOperationHandler = { diagnosisKeys, labConfirmationKey, padding in
            uploadOperationMock
        }

        let mockLabConfirmationKey = LabConfirmationKey(identifier: "", bucketIdentifier: "".data(using: .utf8)!, confirmationKey: "".data(using: .utf8)!, validUntil: Date().addingTimeInterval(20000))

        sut.upload(diagnosisKeys: [], labConfirmationKey: mockLabConfirmationKey)
            .subscribe(onCompleted: {
                streamExpectation.fulfill()
            })
            .dispose()

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - removeLastExposure

    func test_removeLastExposure_shouldCallStorageController() {
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController)

        let removeDataExpectation = expectation(description: "removeData")

        mockStorageController.removeDataHandler = { key, completion in
            XCTAssertTrue((key as? CodableStorageKey<ExposureReport>)?.asString == ExposureDataStorageKey.lastExposureReport.asString)
            removeDataExpectation.fulfill()
        }

        // Initialisation of ExposureDataController apparently already removes some data, so the starting situation is not completely clean
        XCTAssertEqual(mockStorageController.removeDataCallCount, 3)

        sut.removeLastExposure()
            .subscribe()
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockStorageController.removeDataCallCount, 4)
    }

    func test_getAppointmentPhoneNumber() {
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController)

        let subscriptionExpectation = expectation(description: "subscription")

        mockManifestOperation(in: mockOperationProvider, withTestData: .testData())
        mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData())

        sut.getAppointmentPhoneNumber()
            .subscribe(onSuccess: { phoneNumber in
                XCTAssertEqual(phoneNumber, "appointmentPhoneNumber")
                subscriptionExpectation.fulfill()
            })
            .dispose()

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - Private Helper Functions

    private func mockManifestOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                       withTestData testData: ApplicationManifest,
                                       andExpectation expectation: XCTestExpectation? = nil) {
        let operationMock = RequestAppManifestDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .just(testData)
        }
        mockOperationProvider.requestManifestOperation = operationMock
    }

    private func mockApplicationConfigurationOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                       withTestData testData: ApplicationConfiguration,
                                                       andExpectation expectation: XCTestExpectation? = nil) {
        let operationMock = RequestAppConfigurationDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .just(testData)
        }
        mockOperationProvider.requestAppConfigurationOperationHandler = { identifier in operationMock }
    }

    private func mockTreatmentPerspectiveOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                   withTestData testData: TreatmentPerspective,
                                                   andExpectation expectation: XCTestExpectation? = nil) {
        let operationMock = RequestTreatmentPerspectiveDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .empty()
        }
        mockOperationProvider.requestTreatmentPerspectiveDataOperation = operationMock
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

private extension ApplicationConfiguration {
    static func testData(manifestRefreshFrequency: Int = 3600) -> ApplicationConfiguration {
        ApplicationConfiguration(version: 1, manifestRefreshFrequency: manifestRefreshFrequency, decoyProbability: 2, creationDate: Date(), identifier: "identifier", minimumVersion: "1.0.0", minimumVersionMessage: "minimumVersionMessage", appStoreURL: "appStoreURL", requestMinimumSize: 1, requestMaximumSize: 1, repeatedUploadDelay: 1, decativated: false, appointmentPhoneNumber: "appointmentPhoneNumber")
    }
}

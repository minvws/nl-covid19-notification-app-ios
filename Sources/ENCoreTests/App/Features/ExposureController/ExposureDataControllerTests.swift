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

final class ExposureDataControllerTests: TestCase {

    private var sut: ExposureDataController!
    private var mockOperationProvider: ExposureDataOperationProviderMock!
    private var mockStorageController: StorageControllingMock!
    private var mockEnvironmentController: EnvironmentControllingMock!

    override func setUp() {
        super.setUp()

        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593290000) // 27/06/20 20:33

        mockOperationProvider = ExposureDataOperationProviderMock()
        mockStorageController = StorageControllingMock()
        mockEnvironmentController = EnvironmentControllingMock()

        // default mocking
        mockStorageController.requestExclusiveAccessHandler = { completion in completion(self.mockStorageController) }

        sut = ExposureDataController(operationProvider: mockOperationProvider,
                                     storageController: mockStorageController,
                                     environmentController: mockEnvironmentController)
    }

    override class func tearDown() {
        super.tearDown()
        DateTimeTestingOverrides.overriddenCurrentDate = nil
    }

    // MARK: - Tests

    func test_performInitialisationTasks_firstRun_erasesStorage() {

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

        sut.performInitialisationTasks()

        XCTAssertEqual(mockStorageController.removeDataCallCount, 3)
        XCTAssertEqual(mockStorageController.storeCallCount, 1)

        let removedKeysStrings = removedKeys.map { $0.asString }
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.labConfirmationKey.asString))
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.lastExposureReport.asString))
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.pendingLabUploadRequests.asString))

        XCTAssertEqual(receivedKey.asString, ExposureDataStorageKey.firstRunIdentifier.asString)
        XCTAssertEqual(receivedData, Data([116, 114, 117, 101])) // true
    }

    func test_performInitialisationTasks_update_erasesStoredManifest() {
        let removedManifestExpectation = expectation(description: "Removed Manifest")

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

        sut.performInitialisationTasks()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_performInitialisationTasks_shouldRemovePreviousExposureDateIfNeeded() {
        // Arrange

        let removalExpectation = expectation(description: "completion")

        let oldExposureDate = currentDate().addingTimeInterval(.days(-15)).startOfDay!
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(oldExposureDate)
        }

        var removedKeys: [StoreKey] = []
        mockStorageController.removeDataHandler = { key, completion in
            let storeKey = key as! StoreKey
            removedKeys.append(storeKey)
            if storeKey.asString == ExposureDataStorageKey.previousExposureDate.asString {
                removalExpectation.fulfill()
            }
            completion(nil)
        }

        // Act
        sut.performInitialisationTasks()

        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        let removedKeysStrings = removedKeys.map { $0.asString }
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.previousExposureDate.asString))
    }

    func test_performInitialisationTasks_update_ignoresFirstV2Exposure() {
        // Arrange
        let storedIgnoreBoolean = expectation(description: "storedIgnoreBoolean")

        mockEnvironmentController.appVersion = "2.0.0"

        mockStorageController.storeHandler = { data, key, _ in
            if (key as? StoreKey)?.asString == ExposureDataStorageKey.ignoreFirstV2Exposure.asString {

                let jsonDecoder = JSONDecoder()
                let receivedBoolean = try! jsonDecoder.decode(Bool.self, from: data)
                XCTAssertTrue(receivedBoolean)

                storedIgnoreBoolean.fulfill()
            }
        }

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

        // Act
        sut.performInitialisationTasks()

        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_updateTreatmentPerspective_shouldRequestApplicationManifest() {
        // Arrange
        let streamExpectation = expectation(description: "stream")

        let manifestOperationCalledExpectation = expectation(description: "manifestOperationCalled")
        mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: manifestOperationCalledExpectation)

        let treatmentPerspectiveOperationMock = UpdateTreatmentPerspectiveDataOperationProtocolMock()
        treatmentPerspectiveOperationMock.executeHandler = {
            return .empty()
        }
        mockOperationProvider.updateTreatmentPerspectiveDataOperation = treatmentPerspectiveOperationMock

        // Act
        sut.updateTreatmentPerspective()
            .subscribe(onCompleted: {
                streamExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(treatmentPerspectiveOperationMock.executeCallCount, 1)
    }

    func test_upload_shouldRequestApplicationManifestAndAppConfiguration() {
        // Arrange
        let streamExpectation = expectation(description: "stream")

        let manifestOperationCalledExpectation = expectation(description: "manifestOperationCalled")
        mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: manifestOperationCalledExpectation)

        let configurationOperationCalledExpectation = expectation(description: "configurationOperationCalled")
        mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: configurationOperationCalledExpectation)

        let uploadOperationMock = UploadDiagnosisKeysDataOperationProtocolMock()
        uploadOperationMock.executeHandler = {
            return .empty()
        }

        mockOperationProvider.uploadDiagnosisKeysOperationHandler = { _, _, _ in
            uploadOperationMock
        }

        let mockLabConfirmationKey = LabConfirmationKey(identifier: "", bucketIdentifier: "".data(using: .utf8)!, confirmationKey: "".data(using: .utf8)!, validUntil: currentDate().addingTimeInterval(20000))

        // Act
        sut.upload(diagnosisKeys: [], labConfirmationKey: mockLabConfirmationKey)
            .subscribe(onCompleted: {
                streamExpectation.fulfill()
            })
            .dispose()

        // Assert
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(uploadOperationMock.executeCallCount, 1)
    }

    func test_removeLastExposure_shouldCallStorageController() {
        // Arrange
        let removeDataExpectation = expectation(description: "removeData")

        mockStorageController.removeDataHandler = { key, _ in
            XCTAssertTrue((key as? CodableStorageKey<ExposureReport>)?.asString == ExposureDataStorageKey.lastExposureReport.asString)
            removeDataExpectation.fulfill()
        }

        // Act
        sut.removeLastExposure()
            .subscribe()
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(mockStorageController.removeDataCallCount, 1)
    }

    func test_getAppointmentPhoneNumber() {
        // Arrange
        let subscriptionExpectation = expectation(description: "subscription")

        mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData())
        mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData())

        // Act
        sut.getAppointmentPhoneNumber()
            .subscribe(onSuccess: { phoneNumber in
                XCTAssertEqual(phoneNumber, "appointmentPhoneNumber")
                subscriptionExpectation.fulfill()
            })
            .dispose()

        // Assert
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_fetchAndProcessExposureKeySets_shouldRequestApplicationConfiguration() {
        // Arrange
        let completionExpectation = expectation(description: "completion")

        let mockExposureManager = ExposureManagingMock()
        let mockManifestOperation = mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData())
        let mockConfigurationOperation = mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData())
        let mockRequestExposureKeySetsOperation = mockRequestExposureKeySetsDataOperation(in: mockOperationProvider)
        let mockRequestExposureConfigurationOperation = mockRequestExposureConfigurationDataOperation(in: mockOperationProvider, withTestData: .testData())
        let mockProcessExposureKeySetsDataOperation = mockProcessExposureKeySetsDataOperationProtocol(in: mockOperationProvider)

        // Act
        sut.fetchAndProcessExposureKeySets(exposureManager: mockExposureManager)
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations(timeout: 1, handler: nil)

        // Manifest operation is called multiple times during this action. This is intentional and should not lead to multiple network requests
        XCTAssertEqual(mockManifestOperation.executeCallCount, 3)

        XCTAssertEqual(mockConfigurationOperation.executeCallCount, 1)
        XCTAssertEqual(mockRequestExposureKeySetsOperation.executeCallCount, 1)
        XCTAssertEqual(mockRequestExposureConfigurationOperation.executeCallCount, 1)
        XCTAssertEqual(mockProcessExposureKeySetsDataOperation.executeCallCount, 1)
    }

    func test_processPendingUploadRequests() {
        // Arrange
        mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData())
        mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData())
        let mockProcessPendingLabConfirmationUploadRequestsOperation = mockProcessPendingLabConfirmationUploadRequestsDataOperation(in: mockOperationProvider)

        let completionExpectation = expectation(description: "completion")

        // Act
        sut.processPendingUploadRequests()
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockOperationProvider.processPendingLabConfirmationUploadRequestsOperationCallCount, 1)
        XCTAssertEqual(mockProcessPendingLabConfirmationUploadRequestsOperation.executeCallCount, 1)
    }

    func test_updateExposureFirstNotificationReceivedDate() {
        // Arrange
        let date = currentDate()

        // Act
        sut.updateExposureFirstNotificationReceivedDate(date)

        // Assert
        XCTAssertEqual(mockStorageController.requestExclusiveAccessCallCount, 1)
        XCTAssertEqual(mockStorageController.storeCallCount, 1)
    }

    func test_isKnownPreviousExposureDate_withPreviousDate() {
        // Arrange
        let exposureDate = currentDate().startOfDay!

        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(exposureDate)
        }

        // Act
        let result = sut.isKnownPreviousExposureDate(exposureDate)

        // Assert
        XCTAssertTrue(result)
    }

    func test_isKnownPreviousExposureDate_withNoPreviousDate() {
        // Arrange
        mockStorageController.retrieveDataHandler = { _ in
            return nil
        }

        // Act
        let result = sut.isKnownPreviousExposureDate(currentDate())

        // Assert
        XCTAssertFalse(result)
    }

    func test_addPreviousExposureDate() {
        // Arrange
        mockStorageController.removeDataHandler = { key, _ in
            return
        }

        let exposureDate = currentDate().startOfDay!
        let completionExpectation = expectation(description: "completion")

        var receivedDate: Date?
        mockStorageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedDate = try! jsonDecoder.decode(Date.self, from: data)
            completion(nil)
        }

        // Act
        sut.addPreviousExposureDate(exposureDate)
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(mockStorageController.storeCallCount, 1)
        XCTAssertEqual(receivedDate, exposureDate)
    }

    func test_removePreviousExposureDateIfNeeded_withDateLongerThanThresholdDaysAgo() {
        // Arrange
        let oldExposureDate = currentDate().addingTimeInterval(.days(-15)).startOfDay!
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(oldExposureDate)
        }

        var removedKeys: [StoreKey] = []
        mockStorageController.removeDataHandler = { key, completion in
            XCTAssertTrue(Thread.current.qualityOfService == .utility)
            removedKeys.append(key as! StoreKey)
            completion(nil)
        }

        let completionExpectation = expectation(description: "completion")

        // Act
        sut.removePreviousExposureDateIfNeeded()
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(mockStorageController.removeDataCallCount, 1)
        let removedKeysStrings = removedKeys.map { $0.asString }
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.previousExposureDate.asString))
    }

    func test_removePreviousExposureDateIfNeeded_withDateShorterThanThresholdDaysAgo() {
        // Arrange

        let oldExposureDate = currentDate().addingTimeInterval(.days(-14))
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(oldExposureDate)
        }

        let completionExpectation = expectation(description: "completion")

        // Act
        sut.removePreviousExposureDateIfNeeded()
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(mockStorageController.removeDataCallCount, 0)
    }

    func test_updateLastExposureProcessingDateSubject_shouldUpdateExposureProcessingDateSubject() {
        // Arrange
        let completionExpectation = expectation(description: "completion")

        let oldExposureDate = currentDate().addingTimeInterval(.days(-14))
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(oldExposureDate)
        }

        sut.lastSuccessfulExposureProcessingDateObservable
            .subscribe(onNext: { date in
                if date != nil {
                    XCTAssertTrue(Thread.current.qualityOfService == .userInitiated)
                    XCTAssertEqual(date, oldExposureDate)
                    completionExpectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        // Act
        sut.updateLastExposureProcessingDateSubject()

        // Assert
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_getAppConfigFeatureFlags_shouldReturnAppConfigFromStorageController() {
        // Arrange
        let storageExpectation = expectation(description: "storageExpectation")
        mockStorageController.retrieveDataHandler = { key in
            // mock the last run app version
            if (key as? CodableStorageKey<ApplicationConfiguration>)?.asString == ExposureDataStorageKey.appConfiguration.asString {
                storageExpectation.fulfill()
                return try! JSONEncoder().encode(ApplicationConfiguration.testData(featureFlags: [.init(id: "someId", featureEnabled: true)]))
            }
            return nil
        }
        
        // Act
        let featureFlags = sut.getStoredAppConfigFeatureFlags()
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(featureFlags, [.init(id: "someId", featureEnabled: true)])
    }
    
    func test_getAppConfigFeatureFlags_shouldReturnNil() {
        // Arrange
        let storageExpectation = expectation(description: "storageExpectation")
        mockStorageController.retrieveDataHandler = { key in
            // mock the last run app version
            if (key as? CodableStorageKey<ApplicationConfiguration>)?.asString == ExposureDataStorageKey.appConfiguration.asString {
                storageExpectation.fulfill()
                return nil
            }
            return nil
        }
        
        // Act
        let featureFlags = sut.getStoredAppConfigFeatureFlags()
        
        // Assert
        waitForExpectations()
        XCTAssertNil(featureFlags)
    }

    // MARK: - Private Helper Functions

    @discardableResult
    private func mockProcessPendingLabConfirmationUploadRequestsDataOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                                              andExpectation expectation: XCTestExpectation? = nil) -> ProcessPendingLabConfirmationUploadRequestsDataOperationProtocolMock {
        let operationMock = ProcessPendingLabConfirmationUploadRequestsDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .empty()
        }
        mockOperationProvider.processPendingLabConfirmationUploadRequestsOperationHandler = { _ in
            operationMock
        }
        return operationMock
    }

    @discardableResult
    private func mockProcessExposureKeySetsDataOperationProtocol(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                                 andExpectation expectation: XCTestExpectation? = nil) -> ProcessExposureKeySetsDataOperationProtocolMock {
        let operationMock = ProcessExposureKeySetsDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .empty()
        }

        mockOperationProvider.processExposureKeySetsOperationHandler = { _, _, _ in
            operationMock
        }

        return operationMock
    }

    @discardableResult
    private func mockRequestExposureConfigurationDataOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                               withTestData testData: ExposureConfigurationMock,
                                                               andExpectation expectation: XCTestExpectation? = nil) -> RequestExposureConfigurationDataOperationProtocolMock {
        let operationMock = RequestExposureConfigurationDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .just(testData)
        }
        mockOperationProvider.requestExposureConfigurationOperationHandler = { _ in
            operationMock
        }
        return operationMock
    }

    @discardableResult
    private func mockRequestExposureKeySetsDataOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                         andExpectation expectation: XCTestExpectation? = nil) -> RequestExposureKeySetsDataOperationProtocolMock {
        let operationMock = RequestExposureKeySetsDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .empty()
        }
        mockOperationProvider.requestExposureKeySetsOperationHandler = { _ in
            operationMock
        }
        return operationMock
    }

    @discardableResult
    private func mockApplicationManifestOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                  withTestData testData: ApplicationManifest,
                                                  andExpectation expectation: XCTestExpectation? = nil) -> RequestAppManifestDataOperationProtocolMock {
        let operationMock = RequestAppManifestDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .just(testData)
        }
        mockOperationProvider.requestManifestOperation = operationMock
        return operationMock
    }

    @discardableResult
    private func mockApplicationConfigurationOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                       withTestData testData: ApplicationConfiguration,
                                                       andExpectation expectation: XCTestExpectation? = nil) -> RequestAppConfigurationDataOperationProtocolMock {
        let operationMock = RequestAppConfigurationDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .just(testData)
        }
        mockOperationProvider.requestAppConfigurationOperationHandler = { _ in operationMock }
        return operationMock
    }

    private func mockTreatmentPerspectiveOperation(in mockOperationProvider: ExposureDataOperationProviderMock,
                                                   withTestData testData: TreatmentPerspective,
                                                   andExpectation expectation: XCTestExpectation? = nil) {
        let operationMock = UpdateTreatmentPerspectiveDataOperationProtocolMock()
        operationMock.executeHandler = {
            expectation?.fulfill()
            return .empty()
        }
        mockOperationProvider.updateTreatmentPerspectiveDataOperation = operationMock
    }
}

// MARK: - Helper Extensions

private extension TreatmentPerspective {
    static func testData(manifestRefreshFrequency: Int = 3600) -> TreatmentPerspective {
        TreatmentPerspective(resources: ["nl": ["key": "value"]], guidance: .init(layout: []))
    }
}

private extension ApplicationManifest {
    static func testData(creationDate: Date = currentDate(), appConfigurationIdentifier: String = "appConfigurationIdentifier") -> ApplicationManifest {
        ApplicationManifest(exposureKeySetsIdentifiers: [], riskCalculationParametersIdentifier: "riskCalculationParametersIdentifier", appConfigurationIdentifier: appConfigurationIdentifier, creationDate: creationDate, resourceBundle: "resourceBundle")
    }
}

private extension ApplicationConfiguration {
    static func testData(manifestRefreshFrequency: Int = 3600, featureFlags: [ApplicationConfiguration.FeatureFlag] = []) -> ApplicationConfiguration {
        ApplicationConfiguration(version: 1, manifestRefreshFrequency: manifestRefreshFrequency, decoyProbability: 2, creationDate: currentDate(), identifier: "identifier", minimumVersion: "1.0.0", minimumVersionMessage: "minimumVersionMessage", appStoreURL: "appStoreURL", requestMinimumSize: 1, requestMaximumSize: 1, repeatedUploadDelay: 1, decativated: false, appointmentPhoneNumber: "appointmentPhoneNumber", featureFlags: featureFlags, shareKeyURL: "http://www.coronatest.nl")
    }
}

private extension ExposureConfigurationMock {
    static func testData() -> ExposureConfigurationMock {
        ExposureConfigurationMock(minimumRiskScore: 1, reportTypeWeights: [3], infectiousnessWeights: [4], attenuationBucketThresholdDb: [5], attenuationBucketWeights: [6], daysSinceExposureThreshold: 7, minimumWindowScore: 8, daysSinceOnsetToInfectiousness: [])
    }
}

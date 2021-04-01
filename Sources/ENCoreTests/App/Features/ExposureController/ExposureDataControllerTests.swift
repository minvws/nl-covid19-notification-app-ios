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
    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593290000) // 27/06/20 20:33
    }
    
    override class func tearDown() {
        super.tearDown()
        DateTimeTestingOverrides.overriddenCurrentDate = nil
    }
    
    func test_firstRun_erasesStorage() {
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()

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
                                   environmentController: mockEnvironmentController,
                                   randomNumberGenerator: mockRandomNumberGenerator)

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
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        
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
                                   environmentController: mockEnvironmentController,
                                   randomNumberGenerator: mockRandomNumberGenerator)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_subsequentRun_doesNotEraseStorage() {}

    // MARK: - requestTreatmentPerspective

    func test_requestTreatmentPerspective_shouldRequestApplicationManifest() {
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)

        let streamExpectation = expectation(description: "stream")

        let manifestOperationCalledExpectation = expectation(description: "manifestOperationCalled")
        mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: manifestOperationCalledExpectation)

        let treatmentPerspectiveOperationCalled = expectation(description: "treatmentPerspectiveOperationCalled")
        let treatmentPerspectiveOperationMock = UpdateTreatmentPerspectiveDataOperationProtocolMock()
        treatmentPerspectiveOperationMock.executeHandler = {
            treatmentPerspectiveOperationCalled.fulfill()
            return .empty()
        }
        mockOperationProvider.updateTreatmentPerspectiveDataOperation = treatmentPerspectiveOperationMock

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
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)

        let streamExpectation = expectation(description: "stream")

        let manifestOperationCalledExpectation = expectation(description: "manifestOperationCalled")
        mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: manifestOperationCalledExpectation)

        let configurationOperationCalledExpectation = expectation(description: "configurationOperationCalled")
        mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData(), andExpectation: configurationOperationCalledExpectation)

        let uploadCalledExpectation = expectation(description: "uploadCalled")
        let uploadOperationMock = UploadDiagnosisKeysDataOperationProtocolMock()
        uploadOperationMock.executeHandler = {
            uploadCalledExpectation.fulfill()
            return .empty()
        }

        mockOperationProvider.uploadDiagnosisKeysOperationHandler = { _, _, _ in
            uploadOperationMock
        }

        let mockLabConfirmationKey = LabConfirmationKey(identifier: "", bucketIdentifier: "".data(using: .utf8)!, confirmationKey: "".data(using: .utf8)!, validUntil: currentDate().addingTimeInterval(20000))

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
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)

        let removeDataExpectation = expectation(description: "removeData")

        mockStorageController.removeDataHandler = { key, _ in
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
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)

        let subscriptionExpectation = expectation(description: "subscription")

        mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData())
        mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData())

        sut.getAppointmentPhoneNumber()
            .subscribe(onSuccess: { phoneNumber in
                XCTAssertEqual(phoneNumber, "appointmentPhoneNumber")
                subscriptionExpectation.fulfill()
            })
            .dispose()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_fetchAndProcessExposureKeySets_shouldRequestApplicationConfiguration() {
        let mockExposureManager = ExposureManagingMock()
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)

        let completionExpectation = expectation(description: "completion")

        let mockManifestOperation = mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData())
        let mockConfigurationOperation = mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData())
        let mockRequestExposureKeySetsOperation = mockRequestExposureKeySetsDataOperation(in: mockOperationProvider)
        let mockRequestExposureConfigurationOperation = mockRequestExposureConfigurationDataOperation(in: mockOperationProvider, withTestData: .testData())
        let mockProcessExposureKeySetsDataOperation = mockProcessExposureKeySetsDataOperationProtocol(in: mockOperationProvider)

        sut.fetchAndProcessExposureKeySets(exposureManager: mockExposureManager)
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1, handler: nil)

        // Manifest operation is called multiple times during this action. This is intentional and should not lead to multiple network requests
        XCTAssertEqual(mockManifestOperation.executeCallCount, 3)

        XCTAssertEqual(mockConfigurationOperation.executeCallCount, 1)
        XCTAssertEqual(mockRequestExposureKeySetsOperation.executeCallCount, 1)
        XCTAssertEqual(mockRequestExposureConfigurationOperation.executeCallCount, 1)
        XCTAssertEqual(mockProcessExposureKeySetsDataOperation.executeCallCount, 1)
    }

    // MARK: - processPendingUploadRequests

    func test_processPendingUploadRequests() {
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)

        mockApplicationManifestOperation(in: mockOperationProvider, withTestData: .testData())
        mockApplicationConfigurationOperation(in: mockOperationProvider, withTestData: .testData())
        let mockProcessPendingLabConfirmationUploadRequestsOperation = mockProcessPendingLabConfirmationUploadRequestsDataOperation(in: mockOperationProvider)

        let completionExpectation = expectation(description: "completion")

        sut.processPendingUploadRequests()
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockOperationProvider.processPendingLabConfirmationUploadRequestsOperationCallCount, 1)
        XCTAssertEqual(mockProcessPendingLabConfirmationUploadRequestsOperation.executeCallCount, 1)
    }
    
    // MARK: - updateExposureFirstNotificationReceivedDate
    
    func test_updateExposureFirstNotificationReceivedDate() {
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)
        
        mockStorageController.requestExclusiveAccessHandler = { completion in
            completion(mockStorageController)
        }
        
        XCTAssertEqual(mockStorageController.requestExclusiveAccessCallCount, 0)
        XCTAssertEqual(mockStorageController.storeCallCount, 1)
        
        sut.updateExposureFirstNotificationReceivedDate(currentDate())
        
        XCTAssertEqual(mockStorageController.requestExclusiveAccessCallCount, 1)
        XCTAssertEqual(mockStorageController.storeCallCount, 2)
    }
    
    // MARK: - isKnownPreviousExposureDate
    
    func test_isKnownPreviousExposureDate_withPreviousDate() {
        // Arrange
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)
        
        let hashOfExposureDate = "3bdaec38afd41a177167d5478d45d861b4d75de644026ed71d9e5e185a3aba65"
        
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([PreviousExposureDate(exposureDate: hashOfExposureDate, addDate: currentDate())])
        }
        
        let exposureDate = currentDate()
        
        // Act
        let result = sut.isKnownPreviousExposureDate(exposureDate)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_isKnownPreviousExposureDate_withNoPreviousDate() {
        // Arrange
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)
        
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([PreviousExposureDate]())
        }
        
        let exposureDate = currentDate()
        
        // Act
        let result = sut.isKnownPreviousExposureDate(exposureDate)
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_addPreviousExposureDate() {
        // Arrange
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)
        
        mockStorageController.requestExclusiveAccessHandler = { completion in
            completion(mockStorageController)
        }
        
        let exposureDate = Date(timeIntervalSince1970: 0)
        let completionExpectation = expectation(description: "completion")
        
        var receivedDates: [PreviousExposureDate]!
        mockStorageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedDates = try! jsonDecoder.decode([PreviousExposureDate].self, from: data)
            completion(nil)
        }
        
        XCTAssertEqual(mockStorageController.storeCallCount, 1)
        
        // Act
        sut.addPreviousExposureDate(exposureDate)
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(mockStorageController.storeCallCount, 2)
        XCTAssertEqual(receivedDates.first?.addDate, currentDate())
        XCTAssertEqual(receivedDates.first?.exposureDate, "f479418833af89816a4a37e9bd6a0cef2fe38f0bf8e1ccf8ff29777c6325b983")
    }
    
    func test_addDummyPreviousExposureDate() {
        // Arrange
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)
        
        mockStorageController.requestExclusiveAccessHandler = { completion in
            completion(mockStorageController)
        }
        
        mockRandomNumberGenerator.randomDoubleHandler = { _ in
            return 100 // random but predictable double
        }
        
        let completionExpectation = expectation(description: "completion")
        
        var receivedDates: [PreviousExposureDate]!
        mockStorageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedDates = try! jsonDecoder.decode([PreviousExposureDate].self, from: data)
            completion(nil)
        }
        
        XCTAssertEqual(mockStorageController.storeCallCount, 1)
        XCTAssertEqual(mockRandomNumberGenerator.randomDoubleCallCount, 0)
        
        // Act
        sut.addDummyPreviousExposureDate()
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(mockStorageController.storeCallCount, 2)
        XCTAssertEqual(mockRandomNumberGenerator.randomDoubleCallCount, 1)
        XCTAssertEqual(receivedDates.first?.addDate, currentDate())
        XCTAssertEqual(receivedDates.first?.exposureDate, "f479418833af89816a4a37e9bd6a0cef2fe38f0bf8e1ccf8ff29777c6325b983")
    }
    
    func test_purgePreviousExposureDates_withDateLongerThan14DaysAgo() {
        // Arrange
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)
        
        mockStorageController.requestExclusiveAccessHandler = { completion in
            completion(mockStorageController)
        }
        
        let hashOfExposureDate = "SHA256 digest: a660cc30b15a91e9de69b6491194a8ca0316587aed682b3edc6b5235789f2d95"
        let oldAddDate = currentDate().addingTimeInterval(.days(-15))
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([PreviousExposureDate(exposureDate: hashOfExposureDate, addDate: oldAddDate)])
        }
        
        var receivedDates: [PreviousExposureDate]!
        mockStorageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedDates = try! jsonDecoder.decode([PreviousExposureDate].self, from: data)
            completion(nil)
        }
        
        let completionExpectation = expectation(description: "completion")
        
        // Act
        sut.purgePreviousExposureDates()
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(mockStorageController.storeCallCount, 2)
        XCTAssertTrue(receivedDates.isEmpty)
    }
    
    func test_purgePreviousExposureDates_withDateShorterThan14DaysAgo() {
        // Arrange
        let mockOperationProvider = ExposureDataOperationProviderMock()
        let mockStorageController = StorageControllingMock()
        let mockEnvironmentController = EnvironmentControllingMock()
        let mockRandomNumberGenerator = RandomNumberGeneratingMock()
        let sut = ExposureDataController(operationProvider: mockOperationProvider,
                                         storageController: mockStorageController,
                                         environmentController: mockEnvironmentController,
                                         randomNumberGenerator: mockRandomNumberGenerator)
        
        mockStorageController.requestExclusiveAccessHandler = { completion in
            completion(mockStorageController)
        }
        
        let hashOfExposureDate = "SHA256 digest: a660cc30b15a91e9de69b6491194a8ca0316587aed682b3edc6b5235789f2d95"
        let oldAddDate = currentDate().addingTimeInterval(.days(-14))
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode([PreviousExposureDate(exposureDate: hashOfExposureDate, addDate: oldAddDate)])
        }
        
        var receivedDates: [PreviousExposureDate]!
        mockStorageController.storeHandler = { data, _, completion in
            let jsonDecoder = JSONDecoder()
            receivedDates = try! jsonDecoder.decode([PreviousExposureDate].self, from: data)
            completion(nil)
        }
        
        let completionExpectation = expectation(description: "completion")
        
        // Act
        sut.purgePreviousExposureDates()
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(mockStorageController.storeCallCount, 2)
        XCTAssertEqual(receivedDates.first?.addDate, oldAddDate)
        XCTAssertEqual(receivedDates.first?.exposureDate, "SHA256 digest: a660cc30b15a91e9de69b6491194a8ca0316587aed682b3edc6b5235789f2d95")
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
    static func testData(manifestRefreshFrequency: Int = 3600) -> ApplicationConfiguration {
        ApplicationConfiguration(version: 1, manifestRefreshFrequency: manifestRefreshFrequency, decoyProbability: 2, creationDate: currentDate(), identifier: "identifier", minimumVersion: "1.0.0", minimumVersionMessage: "minimumVersionMessage", appStoreURL: "appStoreURL", requestMinimumSize: 1, requestMaximumSize: 1, repeatedUploadDelay: 1, decativated: false, appointmentPhoneNumber: "appointmentPhoneNumber")
    }
}

private extension ExposureConfigurationMock {
    static func testData() -> ExposureConfigurationMock {
        ExposureConfigurationMock(minimumRiskScore: 1, reportTypeWeights: [3], infectiousnessWeights: [4], attenuationBucketThresholdDb: [5], attenuationBucketWeights: [6], daysSinceExposureThreshold: 7, minimumWindowScore: 8, daysSinceOnsetToInfectiousness: [])
    }
}

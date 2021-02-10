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

class ProcessExposureKeySetsDataOperationTests: TestCase {

    private var sut: ProcessExposureKeySetsDataOperation!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!
    private var mockExposureManager: ExposureManagingMock!
    private var mockExposureConfiguration: ExposureConfigurationMock!
    private var mockUserNotificationCenter: UserNotificationCenterMock!
    private var mockApplication: ApplicationControllingMock!
    private var mockFileManager: FileManagingMock!
    private var mockEnvironmentController: EnvironmentControllingMock!
    private var mockLocalPathProvider: LocalPathProvidingMock!
    private var disposeBag = DisposeBag()
    private var mockExposureDataController: ExposureDataControllingMock!

    override func setUpWithError() throws {

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()
        mockExposureManager = ExposureManagingMock()
        mockExposureConfiguration = ExposureConfigurationMock()
        mockUserNotificationCenter = UserNotificationCenterMock()
        mockApplication = ApplicationControllingMock()
        mockFileManager = FileManagingMock()
        mockEnvironmentController = EnvironmentControllingMock()
        mockLocalPathProvider = LocalPathProvidingMock()
        mockExposureDataController = ExposureDataControllingMock()

        // Default handlers
        mockEnvironmentController.gaenRateLimitingType = .dailyLimit
        mockEnvironmentController.maximumSupportedExposureNotificationVersion = .version1
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

        mockLocalPathProvider.pathHandler = { folder in
            if folder == .exposureKeySets {
                return URL(string: "http://someurl.com")!
            }

            return nil
        }

        mockExposureDataController.updateLastSuccessfulExposureProcessingDateHandler = { _ in }

        sut = ProcessExposureKeySetsDataOperation(
            networkController: mockNetworkController,
            storageController: mockStorageController,
            exposureManager: mockExposureManager,
            localPathProvider: mockLocalPathProvider,
            exposureDataController: mockExposureDataController,
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

    func test_shouldNotDetectExposuresIfNoStoredKeySets() {

        let exp = expectation(description: "detectExposuresExpectation")

        let exposureApiBackgroundCallDates = Array(repeating: Date(), count: 5)
        mockApplication.isInBackground = true
        mockStorage(storedKeySetHolders: [], exposureApiBackgroundCallDates: exposureApiBackgroundCallDates)

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 0)
    }

    // If the number of background calls has not reached the limit, a detection call should be made
    func test_shouldDetectExposuresIfBackgroundCallsAvailable() {

        mockApplication.isInBackground = true
        let exposureApiBackgroundCallDates = Array(repeating: Date(), count: 5)

        let exp = expectation(description: "detectExposuresExpectation")

        mockStorage(storedKeySetHolders: [dummyKeySetHolder], exposureApiBackgroundCallDates: exposureApiBackgroundCallDates)

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

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
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

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
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

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
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

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
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 0)
    }

    func test_shouldDetectExposuresIfFileLimitNotReached() {

        mockEnvironmentController.gaenRateLimitingType = .fileLimit

        // 10 processed keysets should not trigger the file limit
        let processedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: Date().addingTimeInterval(-200), creationDate: Date()), count: 10)
        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: Date()), count: 2)

        let exp = expectation(description: "detectExposuresExpectation")

        mockStorage(storedKeySetHolders: processedKeySetHolders + unprocessedKeySetHolders)

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 1)
        XCTAssertEqual(mockExposureManager.detectExposuresArgValues.first?.1.first?.absoluteString, "http://someurl.com/signatureFilename")
        XCTAssertEqual(mockExposureManager.detectExposuresArgValues.first?.1.last?.absoluteString, "http://someurl.com/binaryFilename")
    }

    func test_shouldNotDetectExposuresIfFileLimitReached() {

        mockEnvironmentController.gaenRateLimitingType = .fileLimit

        let keySetHolder = ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: Date().addingTimeInterval(-200), creationDate: Date())
        let processedKeySetHolders = Array(repeating: keySetHolder, count: 20)

        let exp = expectation(description: "detectExposuresExpectation")

        mockStorage(storedKeySetHolders: processedKeySetHolders)

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 0)
    }

    func test_shouldPersistKeySetHolders() {

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")
        let storedKeySetsExpectation = expectation(description: "storedKeySetsExpectation")

        mockStorage(storedKeySetHolders: [dummyKeySetHolder])
        mockStorageController.storeHandler = { object, key, completion in

            if (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString {
                storedKeySetsExpectation.fulfill()
            }

            completion(nil)
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_shouldShowExposureNotificationToUser() throws {

        mockEnvironmentController.gaenRateLimitingType = .fileLimit

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: Date()), count: 2)

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        mockExposureManager.detectExposuresHandler = { _, _, completion in
            let exposureSummary = ExposureDetectionSummaryMock()
            exposureSummary.daysSinceLastExposure = 3

            completion(.success(exposureSummary))
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockUserNotificationCenter.addCallCount, 1)
        let notificationRequest = try XCTUnwrap(mockUserNotificationCenter.addArgValues.first)
        XCTAssertEqual(notificationRequest.content.sound, .default)
        XCTAssertEqual(notificationRequest.content.badge, 0)
        XCTAssertEqual(notificationRequest.content.body, "You were near someone who has coronavirus 3 days ago. Read more in the app.")
    }

    func test_shouldPersistExposureReport() throws {

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: Date()), count: 2)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")
        let storedExposureReportExpectation = expectation(description: "storedExposureReportExpectation")

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)
        mockStorageController.storeHandler = { object, key, completion in
            if (key as? CodableStorageKey<ExposureReport>)?.asString == ExposureDataStorageKey.lastExposureReport.asString {
                storedExposureReportExpectation.fulfill()
            }
            completion(nil)
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_shouldUpdateLastProcessingDate() {

        mockApplication.isInBackground = true
        let exposureApiBackgroundCallDates = Array(repeating: Date(), count: 5)

        let exp = expectation(description: "detectExposuresExpectation")

        let currentDate = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = currentDate

        mockStorage(storedKeySetHolders: [dummyKeySetHolder], exposureApiBackgroundCallDates: exposureApiBackgroundCallDates)
        mockExposureManager.detectExposuresHandler = { _, _, completion in
            completion(.success(ExposureDetectionSummaryMock()))
        }

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureManager.detectExposuresCallCount, 1)
        XCTAssertEqual(mockExposureDataController.updateLastSuccessfulExposureProcessingDateCallCount, 1)
        XCTAssertEqual(mockExposureDataController.updateLastSuccessfulExposureProcessingDateArgValues.first, currentDate)
    }

    func test_shouldRemoveBlobsForProcessedKeySets() throws {

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: Date()), count: 1)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(mockFileManager.removeItemCallCount, 2)
        XCTAssertEqual(mockFileManager.removeItemArgValues.first?.absoluteString, "http://someurl.com/signatureFilename")
        XCTAssertEqual(mockFileManager.removeItemArgValues.last?.absoluteString, "http://someurl.com/binaryFilename")
    }

    // MARK: - Private Helper Functions

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

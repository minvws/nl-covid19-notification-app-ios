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
    private var mockUserNotificationController: UserNotificationControllingMock!
    private var mockApplication: ApplicationControllingMock!
    private var mockFileManager: FileManagingMock!
    private var mockEnvironmentController: EnvironmentControllingMock!
    private var mockLocalPathProvider: LocalPathProvidingMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockRiskCalculationController: RiskCalculationControllingMock!

    override func setUp() {
        super.setUp()

        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593290000) // 27/06/20 20:33

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()
        mockExposureManager = ExposureManagingMock()
        mockExposureConfiguration = ExposureConfigurationMock()
        mockUserNotificationController = UserNotificationControllingMock()
        mockApplication = ApplicationControllingMock()
        mockFileManager = FileManagingMock()
        mockEnvironmentController = EnvironmentControllingMock()
        mockLocalPathProvider = LocalPathProvidingMock()
        mockExposureDataController = ExposureDataControllingMock()
        mockRiskCalculationController = RiskCalculationControllingMock()

        // Default handlers
        mockEnvironmentController.gaenRateLimitingType = .dailyLimit
        mockEnvironmentController.maximumSupportedExposureNotificationVersion = .version2
        mockUserNotificationController.displayExposureNotificationHandler = { _, completion in
            completion(true)
        }
        mockExposureManager.detectExposuresHandler = { _, _, completion in
            completion(.success(ExposureDetectionSummaryMock()))
        }
        mockExposureManager.getExposureWindowsHandler = { _, completion in
            completion(.success([ExposureWindowMock()]))
        }
        mockFileManager.fileExistsHandler = { _, _ in true }
        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }
        mockStorageController.storeHandler = { _, _, completion in
            completion(nil)
        }

        mockLocalPathProvider.pathHandler = { folder in
            if folder == .exposureKeySets {
                return URL(string: "http://someurl.com")!
            }

            return nil
        }

        mockExposureDataController.updateLastSuccessfulExposureProcessingDateHandler = { _ in }
        mockExposureDataController.addPreviousExposureDateHandler = { _ in .empty() }
        mockExposureDataController.isKnownPreviousExposureDateHandler = { _ in false }

        mockRiskCalculationController.getLastExposureDateHandler = { _, _ in
            currentDate()
        }

        sut = ProcessExposureKeySetsDataOperation(
            networkController: mockNetworkController,
            storageController: mockStorageController,
            exposureManager: mockExposureManager,
            localPathProvider: mockLocalPathProvider,
            exposureDataController: mockExposureDataController,
            configuration: mockExposureConfiguration,
            userNotificationController: mockUserNotificationController,
            application: mockApplication,
            fileManager: mockFileManager,
            environmentController: mockEnvironmentController,
            riskCalculationController: mockRiskCalculationController
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        DateTimeTestingOverrides.overriddenCurrentDate = nil
    }

    func test_shouldRetrieveStoredKeySetHolders() {
        let keySetExpectation = expectation(description: "keySetHoldersRequested")
        
        // Stored keysets are request 2 times, once at the start of the operation and once when the result of the operation is stored
        keySetExpectation.expectedFulfillmentCount = 2
        
        let completionExpectation = expectation(description: "subscriptionEnded")
        
        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString {
                keySetExpectation.fulfill()
                return try! JSONEncoder().encode([ExposureKeySetHolder]())
            }

            return nil
        }

        sut.execute()
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        XCTAssertTrue(mockStorageController.retrieveDataArgValues.first is CodableStorageKey<[ExposureKeySetHolder]>)
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_shouldNotDetectExposuresIfNoStoredKeySets() {
        let exp = expectation(description: "detectExposuresExpectation")

        let exposureApiBackgroundCallDates = Array(repeating: currentDate(), count: 5)
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
    
    func test_shouldUpdateProcessingDateIfNoStoredKeySets() {

        let currentDate = Date()
        DateTimeTestingOverrides.overriddenCurrentDate = currentDate
        
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
        XCTAssertEqual(mockExposureDataController.updateLastSuccessfulExposureProcessingDateCallCount, 1)
        XCTAssertEqual(mockExposureDataController.updateLastSuccessfulExposureProcessingDateArgValues.first, currentDate)
    }

    // If the number of background calls has not reached the limit, a detection call should be made
    func test_shouldDetectExposuresIfBackgroundCallsAvailable() {
        mockApplication.isInBackground = true
        let exposureApiBackgroundCallDates = Array(repeating: currentDate(), count: 5)

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
        let exposureApiBackgroundCallDates = Array(repeating: currentDate(), count: 6)

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
        let exposureApiForegroundCallDates = Array(repeating: currentDate(), count: 8)

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
        let exposureApiForegroundCallDates = Array(repeating: currentDate(), count: 9)

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
        let exposureApiForegroundCallDates = Array(repeating: currentDate(), count: 20)
        let exposureApiBackgroundCallDates = Array(repeating: currentDate(), count: 2)

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
        let processedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: currentDate().addingTimeInterval(-200), creationDate: currentDate()), count: 10)
        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 2)

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

        let keySetHolder = ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: currentDate().addingTimeInterval(-200), creationDate: currentDate())
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
        mockStorageController.storeHandler = { _, key, completion in

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

    func test_shouldShowExposureNotificationToUser() {
        mockEnvironmentController.gaenRateLimitingType = .fileLimit

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 2)

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        mockRiskCalculationController.getLastExposureDateHandler = { _, _ in
            Calendar.current.date(byAdding: .day, value: -3, to: currentDate())
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockUserNotificationController.displayExposureNotificationCallCount, 1)
        XCTAssertEqual(mockExposureDataController.updateExposureFirstNotificationReceivedDateCallCount, 1)
    }

    func test_shouldNotShowExposureNotificationIfIgnoringFirstV2Exposure() {
        mockEnvironmentController.gaenRateLimitingType = .fileLimit
        mockExposureDataController.ignoreFirstV2Exposure = true

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 2)

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        let exposureDate = Calendar.current.date(byAdding: .day, value: -3, to: currentDate())
        mockRiskCalculationController.getLastExposureDateHandler = { _, _ in
            exposureDate
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureDataController.addPreviousExposureDateCallCount, 1)
        XCTAssertEqual(mockExposureDataController.addPreviousExposureDateArgValues.first, exposureDate)
        XCTAssertEqual(mockUserNotificationController.displayExposureNotificationCallCount, 0)
        XCTAssertFalse(mockExposureDataController.ignoreFirstV2Exposure)
    }

    func test_shouldResetV2IgnoreBoolean_withoutExposure() {
        mockEnvironmentController.gaenRateLimitingType = .fileLimit
        mockExposureDataController.ignoreFirstV2Exposure = true

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 2)

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        mockRiskCalculationController.getLastExposureDateHandler = { _, _ in
            nil
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockUserNotificationController.displayExposureNotificationCallCount, 0)
        XCTAssertFalse(mockExposureDataController.ignoreFirstV2Exposure)
    }

    func test_shouldNotShowExposureNotificationForPreviousExposureDate() {
        mockEnvironmentController.gaenRateLimitingType = .fileLimit
        mockExposureDataController.isKnownPreviousExposureDateHandler = { date in
            XCTAssertEqual(date.timeIntervalSince1970, 1593030800.0)
            return true
        }

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 2)

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        mockRiskCalculationController.getLastExposureDateHandler = { _, _ in
            Calendar.current.date(byAdding: .day, value: -3, to: currentDate())
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockUserNotificationController.displayExposureNotificationCallCount, 0)
    }

    func test_shouldShowExposureNotificationIfNewerExposureDateExists() {
        let today = Date(timeIntervalSince1970: 1618826400) // Monday, April 19, 2021 10:00:00
        let todayExposureDate = Date(timeIntervalSince1970: 1618790400) // Monday, April 19, 2021 0:00:00
        let previousExposureDate = Date(timeIntervalSince1970: 1618704000) // Sunday, April 18, 2021 0:00:00
        DateTimeTestingOverrides.overriddenCurrentDate = today

        mockEnvironmentController.gaenRateLimitingType = .fileLimit

        mockRiskCalculationController.getLastExposureDateHandler = { _, _ in
            todayExposureDate
        }

        let unprocessedKeySetHolder = ExposureKeySetHolder(identifier: "identifier",
                                                           signatureFilename: "signatureFilename",
                                                           binaryFilename: "binaryFilename",
                                                           processDate: nil,
                                                           creationDate: todayExposureDate)

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString {
                return try! JSONEncoder().encode([unprocessedKeySetHolder])
            } else if (key as? CodableStorageKey<ExposureReport>)?.asString == ExposureDataStorageKey.lastExposureReport.asString {
                return try! JSONEncoder().encode(ExposureReport(date: previousExposureDate))
            }
            return nil
        }

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(today.days(sinceDate: previousExposureDate), 1)
        XCTAssertEqual(mockRiskCalculationController.getLastExposureDateCallCount, 1)
        XCTAssertEqual(mockUserNotificationController.displayExposureNotificationCallCount, 1)        
        XCTAssertEqual(mockExposureDataController.updateExposureFirstNotificationReceivedDateCallCount, 1)
    }

    func test_shouldNotShowExposureNotificationForExposureMoreThan14DaysAgo() {
        mockEnvironmentController.gaenRateLimitingType = .fileLimit

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 2)

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        mockExposureManager.detectExposuresHandler = { _, _, completion in
            let exposureSummary = ExposureDetectionSummaryMock()
            exposureSummary.daysSinceLastExposure = 15
            completion(.success(exposureSummary))
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockUserNotificationController.displayExposureReminderNotificationCallCount, 0)
    }

    func test_shouldStoreExposureInPreviousExposureDates() {
        mockEnvironmentController.gaenRateLimitingType = .fileLimit

        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 2)

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")

        mockRiskCalculationController.getLastExposureDateHandler = { _, _ in
            Calendar.current.date(byAdding: .day, value: -3, to: currentDate())
        }

        sut.execute()
            .subscribe(onCompleted: {
                subscriptionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockExposureDataController.addPreviousExposureDateCallCount, 1)
        XCTAssertEqual(mockExposureDataController.addPreviousExposureDateArgValues.first?.timeIntervalSince1970, 1593030800.0)
    }

    func test_shouldPersistExposureReport() {
        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 2)

        let subscriptionExpectation = expectation(description: "subscriptionExpectation")
        let storedExposureReportExpectation = expectation(description: "storedExposureReportExpectation")

        mockStorage(storedKeySetHolders: unprocessedKeySetHolders)
        mockStorageController.storeHandler = { _, key, completion in
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
        let exposureApiBackgroundCallDates = Array(repeating: currentDate(), count: 5)

        let exp = expectation(description: "detectExposuresExpectation")

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
        XCTAssertEqual(mockExposureDataController.updateLastSuccessfulExposureProcessingDateArgValues.first, currentDate())
    }

    func test_shouldRemoveBlobsForProcessedKeySets() {
        let unprocessedKeySetHolders = Array(repeating: ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate()), count: 1)

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
        ExposureKeySetHolder(identifier: "identifier", signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate())
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

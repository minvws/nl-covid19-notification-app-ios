/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ExposureNotification
import Foundation
import XCTest

final class ExposureManagerTests: TestCase {
    private var sut: ExposureManager!
    private var mockManager: ENManagingMock!
    private var mockEnvironmentController: EnvironmentControllingMock!

    override func setUp() {
        super.setUp()

        mockManager = ENManagingMock()
        mockEnvironmentController = EnvironmentControllingMock()
        
        sut = ExposureManager(manager: mockManager,
                              environmentController: mockEnvironmentController)
    }

    func test_deinit_callsDeactivate() {
        XCTAssertEqual(mockManager.invalidateCallCount, 0)

        sut = nil

        XCTAssertEqual(mockManager.invalidateCallCount, 1)
    }

    func test_activate_callsManager_returnsExposureNotificationStatusWhenNoError() {
        mockManager.activateHandler = { completion in
            completion(nil)
        }

        ENManagingMock.authorizationStatus = .authorized
        mockManager.exposureNotificationStatus = .active

        XCTAssertEqual(mockManager.activateCallCount, 0)

        sut.activate { status in
            XCTAssertEqual(status, .active)
        }

        XCTAssertEqual(mockManager.activateCallCount, 1)
    }

    func test_activate_callsManager_returnsInactivateStateWhenError() {
        mockManager.activateHandler = { completion in
            completion(ENError(.internal))
        }

        XCTAssertEqual(mockManager.activateCallCount, 0)

        sut.activate { status in
            XCTAssertEqual(status, ExposureManagerStatus.inactive(.unknown))
        }

        XCTAssertEqual(mockManager.activateCallCount, 1)
    }
    
    func test_deactivate_alreadyDisabled() {
        // Arrange
        mockManager.exposureNotificationEnabled = false
        
        // Act
        sut.deactivate()
        
        // Assert
        XCTAssertEqual(mockManager.setExposureNotificationEnabledCallCount, 0)
    }
    
    func test_deactivate() {
        // Arrange
        mockManager.exposureNotificationEnabled = true
        
        // Act
        sut.deactivate()
        
        // Assert
        XCTAssertEqual(mockManager.setExposureNotificationEnabledCallCount, 1)
    }
    
    func test_detectExposures_shouldCallManager() {
        // Arrange
        mockManager.detectExposuresHandler = { _, _, completion in
            completion(ENExposureDetectionSummary(), nil)
            return .init(totalUnitCount: 0)
        }
        
        let completionExpectation = expectation(description: "completionExpectation")
        let configuration = ExposureConfigurationMock.testData()
        let urls = [URL(string: "http://www.someurl.com")!]
        
        // Act
        sut.detectExposures(configuration: configuration, diagnosisKeyURLs: urls) { (result) in
            guard case let .success(summary) = result else {
                XCTFail("Error thrown when none expected")
                return
            }
            XCTAssertNotNil(summary)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations()
    }
    
    func test_detectExposures_shouldForwardManagerError() {
        // Arrange
        mockManager.detectExposuresHandler = { _, _, completion in
            completion(nil, ExposureManagerError.bluetoothOff)
            return .init(totalUnitCount: 0)
        }
        
        let completionExpectation = expectation(description: "completionExpectation")
        let configuration = ExposureConfigurationMock.testData()
        let urls = [URL(string: "http://www.someurl.com")!]
        
        // Act
        sut.detectExposures(configuration: configuration, diagnosisKeyURLs: urls) { (result) in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but none thrown")
                return
            }
            XCTAssertEqual(error, .bluetoothOff)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations()
    }
    
    func test_getExposureWindows_shouldReturnErrorForIncorrectSummaryType() {
        // Arrange
        let completionExpectation = expectation(description: "completionExpectation")
        let summary = ExposureDetectionSummaryMock()
                
        // Act
        sut.getExposureWindows(summary: summary) { (result) in
            guard case let .failure(error) = result else {
                XCTFail("failure expected")
                return
            }
            XCTAssertEqual(error, .internalTypeMismatch)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations()
    }
    
    func test_getExposureWindows_shouldCallManager() {
        // Arrange
        mockManager.getExposureWindowsHandler = { _, completion in
            completion([ENExposureWindow()], nil)
            return .init(totalUnitCount: 0)
        }
        
        let completionExpectation = expectation(description: "completionExpectation")
        let summary = ENExposureDetectionSummary()
                
        // Act
        sut.getExposureWindows(summary: summary) { (result) in
            guard case let .success(windows) = result else {
                XCTFail("no success returned")
                return
            }
            XCTAssertEqual(windows?.count, 1)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockManager.getExposureWindowsCallCount, 1)
    }
    
    func test_getExposureWindows_shouldForwardManagerError() {
        // Arrange
        mockManager.getExposureWindowsHandler = { _, completion in
            completion(nil, ExposureManagerError.bluetoothOff)
            return .init(totalUnitCount: 0)
        }
        
        let completionExpectation = expectation(description: "completionExpectation")
        let summary = ENExposureDetectionSummary()
                
        // Act
        sut.getExposureWindows(summary: summary) { (result) in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but none thrown")
                return
            }
            XCTAssertEqual(error, .bluetoothOff)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockManager.getExposureWindowsCallCount, 1)
    }

    func test_getDiagnosisKeys_shouldReturnKeys() {
        // Arrange
        let completionExpectation = expectation(description: "completionExpectation")
        mockManager.getDiagnosisKeysHandler = { completion in
            let keys = self.diagnosisKeys()
            completion(keys, nil)
        }

        XCTAssertEqual(mockManager.getDiagnosisKeysCallCount, 0)

        // Act
        sut.getDiagnosisKeys { result in
            guard case let .success(keys) = result else {
                XCTFail("Expected error but none thrown")
                return
            }
            
            XCTAssertEqual(keys.count, 4)
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations()
        XCTAssertEqual(mockManager.getDiagnosisKeysCallCount, 1)
        XCTAssertEqual(mockManager.getTestDiagnosisKeysCallCount, 0)
    }
    
    func test_getDiagnosisKeys_shouldForwardManagerError() {
        // Arrange
        let completionExpectation = expectation(description: "completionExpectation")
        mockManager.getDiagnosisKeysHandler = { completion in
            completion(nil, ExposureManagerError.bluetoothOff)
            return
        }

        XCTAssertEqual(mockManager.getDiagnosisKeysCallCount, 0)

        // Act
        sut.getDiagnosisKeys { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but none thrown")
                return
            }
            XCTAssertEqual(error, .bluetoothOff)
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations()
        XCTAssertEqual(mockManager.getDiagnosisKeysCallCount, 1)
        XCTAssertEqual(mockManager.getTestDiagnosisKeysCallCount, 0)
    }
    
    func test_setExposureNotificationEnabled() {
        // Arrange
        let completionExpectation = expectation(description: "completionExpectation")
        mockManager.setExposureNotificationEnabledHandler = {_, completion in
            completion(nil)
        }
        
        XCTAssertEqual(mockManager.setExposureNotificationEnabledCallCount, 0)
        
        // Act
        sut.setExposureNotificationEnabled(true) { (result) in
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockManager.setExposureNotificationEnabledCallCount, 1)
    }
    
    func test_setExposureNotificationEnabled_shouldForwardManagerError() {
        // Arrange
        let completionExpectation = expectation(description: "completionExpectation")
        mockManager.setExposureNotificationEnabledHandler = {_, completion in
            completion(ExposureManagerError.bluetoothOff)
        }
        
        
        XCTAssertEqual(mockManager.setExposureNotificationEnabledCallCount, 0)
        
        // Act
        sut.setExposureNotificationEnabled(true) { (result) in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but none thrown")
                return
            }
            XCTAssertEqual(error, .bluetoothOff)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockManager.setExposureNotificationEnabledCallCount, 1)
    }
    
    func test_getExposureNotificationStatus() {
        // Arrange
        let testInput: [(authorizationStatus: ENAuthorizationStatus,
                         isiOS14orHigher: Bool,
                         exposureNotificationStatus: ENStatus,
                         expectedManagerStatus: ExposureManagerStatus)] =
            [
                (.unknown, true, .active, .notAuthorized),
                (.unknown, false, .active, .notAuthorized),
                (.authorized, false, .active, .active),
                (.authorized, false, .bluetoothOff, .inactive(.bluetoothOff)),
                (.authorized, false, .disabled, .inactive(.disabled)),
                (.authorized, false, .restricted, .inactive(.restricted)),
                (.authorized, false, .paused, .inactive(.unknown)),
                (.notAuthorized, false, .unauthorized, .authorizationDenied),
                (.restricted, false, .restricted, .inactive(.restricted))
            ]
        
        testInput.forEach { (input) in
            ENManagingMock.authorizationStatus = input.authorizationStatus
            mockManager.exposureNotificationStatus = input.exposureNotificationStatus
            mockEnvironmentController.isiOS13orHigher = input.isiOS14orHigher
        
            // Act
            let result = sut.getExposureNotificationStatus()
        
            // Assert
            XCTAssertEqual(result, input.expectedManagerStatus)
        }
    }
    
    func test_setLaunchActivityHandler_shouldCallManager() {
        // Arrange
        XCTAssertEqual(mockManager.setLaunchActivityHandlerCallCount, 0)
        
        // Act
        sut.setLaunchActivityHandler { (_) in }
        
        // Assert
        XCTAssertEqual(mockManager.setLaunchActivityHandlerCallCount, 1)
    }

    private func diagnosisKeys() -> [ENTemporaryExposureKey] {
        return (0 ... 3).map { _ in
            ENTemporaryExposureKey()
        }
    }
}

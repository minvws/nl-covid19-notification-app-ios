/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

class AppRootTests: TestCase {
    
    private var mockRootBuilder: RootBuildableMock!
    private var sut: AppRoot!
    private var window: UIWindow!

    override func setUpWithError() throws {
        
        mockRootBuilder = RootBuildableMock()
        
        window = UIWindow(frame: .zero)
        
        sut = AppRoot(rootBuilder: mockRootBuilder)
    }

    func test_attach_shouldSetEntryPointAsRootViewController() {
        // Arrange
        let mockViewController = UIViewController()
        createAppEntryPoint(withViewController: mockViewController)
        
        // Act
        sut.attach(toWindow: window)
        
        // Assert
        XCTAssertNotNil(window.rootViewController)
        XCTAssertTrue(window.rootViewController === mockViewController)
    }
    
    func test_attach_shouldNotSetEntryPointAsRootViewControllerTwice() {
        // Arrange
        let buildExpectation = expectation(description: "rootbuilder")
        let mockAppEntryPoint = AppEntryPointMock(uiviewController: UIViewController())
        mockRootBuilder.buildHandler = {
            buildExpectation.fulfill()
            return mockAppEntryPoint
        }
        
        // Act
        sut.attach(toWindow: window)
        sut.attach(toWindow: window)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertNotNil(window.rootViewController)
        XCTAssertTrue(window.rootViewController === mockAppEntryPoint.uiviewController)
    }
    
    func test_start_shouldStartEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint()
        
        // Act
        sut.start()
        
        // Assert
        
        XCTAssertEqual(mockAppEntryPoint.startCallCount, 1)
    }
    
    func test_start_shouldNotStartEntryPointWithoutAttachedAppEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint(attachWindow: false)
        
        // Act
        sut.start()
        
        // Assert
        
        XCTAssertEqual(mockAppEntryPoint.startCallCount, 0)
    }
    
    func test_receiveRemoteNotification_shouldUpdatePushNotificationStream() {
        // Arrange
        let mockMutablePushNotificationStream = MutablePushNotificationStreamingMock()
        createAppEntryPoint(mutablePushNotificationStream: mockMutablePushNotificationStream)
        let mockNotificationResponse = NotificationResponseMock()
        mockNotificationResponse.notificationRequestIdentifier = PushNotificationIdentifier.appUpdateRequired.rawValue
        
        // Act
        sut.receiveRemoteNotification(response: mockNotificationResponse)
        
        // Assert
        XCTAssertEqual(mockMutablePushNotificationStream.updateCallCount, 1)
        XCTAssertEqual(mockMutablePushNotificationStream.updateArgValues.first, PushNotificationIdentifier.appUpdateRequired)
    }
    
    func test_receiveRemoteNotification_withUnknownIdentifier_shouldNotUpdatePushNotificationStream() {
        // Arrange
        let mockMutablePushNotificationStream = MutablePushNotificationStreamingMock()
        createAppEntryPoint(mutablePushNotificationStream: mockMutablePushNotificationStream)
        let mockNotificationResponse = NotificationResponseMock()
        mockNotificationResponse.notificationRequestIdentifier = "someUnknownIdentifier"
        
        // Act
        sut.receiveRemoteNotification(response: mockNotificationResponse)
        
        // Assert
        XCTAssertEqual(mockMutablePushNotificationStream.updateCallCount, 0)
    }
    
    func test_receiveForegroundNotification_shouldUpdatePushNotificationStream() {
        // Arrange
        let mockMutablePushNotificationStream = MutablePushNotificationStreamingMock()
        createAppEntryPoint(mutablePushNotificationStream: mockMutablePushNotificationStream)
        let mockNotification = UserNotificationMock()
        
        // Act
        sut.receiveForegroundNotification(mockNotification)
        
        // Assert
        XCTAssertEqual(mockMutablePushNotificationStream.updateNotificationCallCount, 1)
        XCTAssertTrue(mockMutablePushNotificationStream.updateNotificationArgValues.first === mockNotification)
    }
    
    func test_didBecomeActive_shouldCallAppEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint()
        
        // Act
        sut.didBecomeActive()
        
        // Assert
        XCTAssertEqual(mockAppEntryPoint.didBecomeActiveCallCount, 1)
    }
    
    func test_didBecomeActive_shouldNotCallAppEntryPointWithoutAttachedAppEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint(attachWindow: false)
        
        // Act
        sut.didBecomeActive()
        
        // Assert
        XCTAssertEqual(mockAppEntryPoint.didBecomeActiveCallCount, 0)
    }
    
    func test_didEnterForeground_shouldCallAppEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint()
        
        // Act
        sut.didEnterForeground()
        
        // Assert
        XCTAssertEqual(mockAppEntryPoint.didEnterForegroundCallCount, 1)
    }
    
    func test_didEnterForeground_shouldNotCallAppEntryPointWithoutAttachedAppEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint(attachWindow: false)
        
        // Act
        sut.didEnterForeground()
        
        // Assert
        XCTAssertEqual(mockAppEntryPoint.didEnterForegroundCallCount, 0)
    }
    
    func test_didEnterBackground_shouldCallAppEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint()
        
        // Act
        sut.didEnterBackground()
        
        // Assert
        XCTAssertEqual(mockAppEntryPoint.didEnterBackgroundCallCount, 1)
    }
    
    func test_didEnterBackground_shouldNotCallAppEntryPointWithoutAttachedAppEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint(attachWindow: false)
        
        // Act
        sut.didEnterBackground()
        
        // Assert
        XCTAssertEqual(mockAppEntryPoint.didEnterBackgroundCallCount, 0)
    }
    
    func test_handle_shouldCallAppEntryPoint() {
        // Arrange
        let mockAppEntryPoint = createAppEntryPoint()
        let mockBackgroundTask = BackgroundTaskMock()
        
        // Act
        sut.handle(backgroundTask: mockBackgroundTask)
        
        // Assert
        XCTAssertEqual(mockAppEntryPoint.handleCallCount, 1)
        XCTAssertTrue(mockAppEntryPoint.handleArgValues.first === mockBackgroundTask)
    }
    
    // MARK: - Private Helper Functions
    @discardableResult
    private func createAppEntryPoint(withViewController viewController: UIViewController = UIViewController(), mutablePushNotificationStream: MutablePushNotificationStreaming = MutablePushNotificationStreamingMock(), attachWindow: Bool = true) -> AppEntryPointMock {
        let mockAppEntryPoint = AppEntryPointMock(uiviewController: viewController, mutablePushNotificationStream: mutablePushNotificationStream)
        mockRootBuilder.buildHandler = {
            return mockAppEntryPoint
        }
        if attachWindow {
            sut.attach(toWindow: window)
        }
        return mockAppEntryPoint
    }

}

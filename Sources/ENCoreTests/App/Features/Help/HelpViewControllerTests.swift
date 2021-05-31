/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class HelpViewControllerTests: TestCase {
    
    private var sut: HelpViewController!
    private var mockListener: HelpListenerMock!
    private var mockExposureController: ExposureControllingMock!
    private var mockRouter: HelpRoutingMock!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        mockListener = HelpListenerMock()
        mockRouter = HelpRoutingMock()
        mockExposureController = ExposureControllingMock()
        
        sut = HelpViewController(
            listener: mockListener,
            shouldShowEnableAppButton: true,
            exposureController: mockExposureController,
            theme: theme
        )
        
        sut.router = mockRouter
    }
    
    // MARK: - Tests
    
    func test_helpOverviewRequestsRouteTo_shouldCallRouter() throws {
        // Arrange
        XCTAssertEqual(mockRouter.routeToCallCount, 0)
        
        // Act
        sut.helpOverviewRequestsRouteTo(entry: .notificationExplanation(title: "title", linkedContent: []))
        
        // Assert
        XCTAssertEqual(mockRouter.routeToCallCount, 1)

        let arguments = try XCTUnwrap(mockRouter.routeToArgValues.first)
        
        if case HelpOverviewEntry.notificationExplanation(let title, let linkedcontent) = arguments.0 {
            XCTAssertEqual(title, "title")
            XCTAssertTrue(linkedcontent.isEmpty)
        } else {
            XCTFail("unexpected routing arguments")
            return
        }
    }
    
    func test_helpOverviewRequestsDismissal() {
        // Arrange
        XCTAssertEqual(mockRouter.detachHelpOverviewCallCount, 0)

        // Act
        sut.helpOverviewRequestsDismissal(shouldDismissViewController: true)

        // Assert
        XCTAssertEqual(mockRouter.detachHelpOverviewCallCount, 1)
        XCTAssertEqual(mockRouter.detachHelpOverviewArgValues.first, true)
    }
    
    func test_helpOverviewDidTapEnableAppButton() {
        // Arrange
        XCTAssertEqual(mockRouter.detachHelpOverviewCallCount, 0)
        XCTAssertEqual(mockListener.helpRequestsEnableAppCallCount, 0)
        
        // Act
        sut.helpOverviewDidTapEnableAppButton()
        
        // Assert
        XCTAssertEqual(mockRouter.detachHelpOverviewCallCount, 1)
        XCTAssertEqual(mockRouter.detachHelpOverviewArgValues.first, true)
        XCTAssertEqual(mockListener.helpRequestsEnableAppCallCount, 1)
    }
    
    func test_helpDetailRequestsDismissal() {
        // Arrange
        XCTAssertEqual(mockRouter.detachHelpDetailCallCount, 0)
        
        // Act
        sut.helpDetailRequestsDismissal(shouldDismissViewController: true)
        
        // Assert
        XCTAssertEqual(mockRouter.detachHelpDetailCallCount, 1)
        XCTAssertEqual(mockRouter.detachHelpDetailArgValues.first, true)
    }
    
    func test_helpDetailDidTapEnableAppButton() {
        // Arrange
        XCTAssertEqual(mockRouter.detachHelpDetailCallCount, 0)
        XCTAssertEqual(mockListener.helpRequestsEnableAppCallCount, 0)
        
        // Act
        sut.helpDetailDidTapEnableAppButton()
        
        // Assert
        XCTAssertEqual(mockRouter.detachHelpDetailCallCount, 1)
        XCTAssertEqual(mockRouter.detachHelpDetailArgValues.first, true)
        XCTAssertEqual(mockListener.helpRequestsEnableAppCallCount, 1)
    }
    
    func test_helpDetailRequestRedirect() {
        // Arrange
        let overviewEntry = HelpOverviewEntry.notificationExplanation(title: "title", linkedContent: [])
        XCTAssertEqual(mockRouter.routeToCallCount, 0)
        
        // Act
        sut.helpDetailRequestRedirect(to: overviewEntry)
        
        // Assert
        XCTAssertEqual(mockRouter.routeToCallCount, 1)
        XCTAssertEqual(mockRouter.routeToArgValues.first?.0.title, "title")
    }
    
    func test_receivedNotificationWantsDismissal() {
        // Arrange
        XCTAssertEqual(mockRouter.detachReceivedNotificationCallCount, 0)
        
        // Act
        sut.receivedNotificationWantsDismissal(shouldDismissViewController: true)
        
        // Assert
        XCTAssertEqual(mockRouter.detachReceivedNotificationCallCount, 1)
        XCTAssertEqual(mockRouter.detachReceivedNotificationArgValues.first, true)
    }
    
    func test_receivedNotificationRequestRedirect() {
        // Arrange
        let overviewEntry = HelpOverviewEntry.notificationExplanation(title: "title", linkedContent: [])
        XCTAssertEqual(mockRouter.routeToCallCount, 0)
        
        // Act
        sut.receivedNotificationRequestRedirect(to: overviewEntry)
        
        // Assert
        XCTAssertEqual(mockRouter.routeToCallCount, 1)
        XCTAssertEqual(mockRouter.routeToArgValues.first?.0.title, "title")
    }
    
    func test_receivedNotificationActionButtonTapped() {
        // Arrange
        XCTAssertEqual(mockRouter.detachReceivedNotificationCallCount, 0)
        XCTAssertEqual(mockListener.helpRequestsEnableAppCallCount, 0)
        
        // Act
        sut.receivedNotificationActionButtonTapped()
        
        // Assert
        XCTAssertEqual(mockRouter.detachReceivedNotificationCallCount, 1)
        XCTAssertEqual(mockRouter.detachReceivedNotificationArgValues.first, true)
        XCTAssertEqual(mockListener.helpRequestsEnableAppCallCount, 1)
    }
    
    func test_viewWillAppear_shouldRouteToOverview() {
        // Arrange
        XCTAssertEqual(mockRouter.routeToOverviewCallCount, 0)
        
        // Act
        sut.viewWillAppear(true)
        
        // Assert
        XCTAssertEqual(mockRouter.routeToOverviewCallCount, 1)
    }
    
    func test_didTapClose_shouldDetachOverview() {
        // Arrange
        XCTAssertEqual(mockRouter.detachHelpOverviewCallCount, 0)
        XCTAssertEqual(mockListener.helpRequestsDismissalCallCount, 0)
        
        // Act
        sut.didTapClose()
        
        // Assert
        XCTAssertEqual(mockRouter.detachHelpOverviewCallCount, 1)
        XCTAssertEqual(mockListener.helpRequestsDismissalCallCount, 1)
    }
    
}

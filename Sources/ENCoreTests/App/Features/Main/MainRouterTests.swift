/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class MainRouterTests: TestCase {

    private let mockViewController = MainViewControllableMock()
    private let mockStatusBuilder = StatusBuildableMock()
    private let mockMoreInformationBuilder = MoreInformationBuildableMock()
    private let mockAboutBuilder = AboutBuildableMock()
    private let mockShareBuilder = ShareSheetBuildableMock()
    private let mockReceivedNotificationBuilder = ReceivedNotificationBuildableMock()
    private let mockRequestTestBuilder = RequestTestBuildableMock()
    private let mockMessageBuilder = MessageBuildableMock()
    private let mockEnableSettingBuilder = EnableSettingBuildableMock()
    private let mockWebviewBuilder = WebviewBuildableMock()
    private let mockSettingsBuilder = SettingsBuildableMock()
    private let mockKeySharingBuilder = KeySharingBuildableMock()
    private let mockApplicationController = ApplicationControllingMock()

    private var sut: MainRouter!

    override func setUp() {
        super.setUp()

        sut = MainRouter(viewController: mockViewController,
                         statusBuilder: mockStatusBuilder,
                         moreInformationBuilder: mockMoreInformationBuilder,
                         aboutBuilder: mockAboutBuilder,
                         shareBuilder: mockShareBuilder,
                         receivedNotificationBuilder: mockReceivedNotificationBuilder,
                         requestTestBuilder: mockRequestTestBuilder,
                         keySharingBuilder: mockKeySharingBuilder,
                         messageBuilder: mockMessageBuilder,
                         enableSettingBuilder: mockEnableSettingBuilder,
                         webviewBuilder: mockWebviewBuilder,
                         settingsBuilder: mockSettingsBuilder,
                         applicationController: mockApplicationController)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(mockViewController.routerSetCallCount, 1)
    }

    func test_attachStatus_callsBuildAndEmbed() {
        // Arrange
        var receivedListener: StatusListener!
        var receivedAnchor: NSLayoutYAxisAnchor!
        mockStatusBuilder.buildHandler = { listener, anchor in
            receivedListener = listener
            receivedAnchor = anchor

            return StatusViewControllableMock()
        }

        XCTAssertEqual(mockStatusBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.embedCallCount, 0)

        let anchor = NSLayoutYAxisAnchor()

        // Act
        sut.attachStatus(topAnchor: anchor)

        // Assert
        XCTAssertEqual(mockViewController.embedCallCount, 1)
        XCTAssertEqual(mockStatusBuilder.buildCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === mockViewController)
        XCTAssert(receivedAnchor === anchor)
    }

    func test_callAttachStatusTwice_callsBuildAndEmbedOnce() {
        // Arrange
        var receivedListener: StatusListener!
        var receivedAnchor: NSLayoutYAxisAnchor!
        mockStatusBuilder.buildHandler = { listener, anchor in
            receivedListener = listener
            receivedAnchor = anchor

            return StatusViewControllableMock()
        }

        XCTAssertEqual(mockStatusBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.embedCallCount, 0)

        // Act
        let anchor = NSLayoutYAxisAnchor()
        sut.attachStatus(topAnchor: anchor)
        sut.attachStatus(topAnchor: NSLayoutYAxisAnchor())

        // Assert
        XCTAssertEqual(mockViewController.embedCallCount, 1)
        XCTAssertEqual(mockStatusBuilder.buildCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === mockViewController)
        XCTAssert(receivedAnchor === anchor)
    }

    func test_attachMoreInformation_callsBuildAndEmbed() {
        // Arrange
        var receivedListener: MoreInformationListener!
        mockMoreInformationBuilder.buildHandler = { listener in
            receivedListener = listener

            return MoreInformationViewControllableMock()
        }

        XCTAssertEqual(mockMoreInformationBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.embedCallCount, 0)

        // Act
        sut.attachMoreInformation()

        // Assert
        XCTAssertEqual(mockViewController.embedCallCount, 1)
        XCTAssertEqual(mockMoreInformationBuilder.buildCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === mockViewController)
    }

    func test_callAttachMoreInformationTwice_callsBuildAndEmbedOnce() {
        // Arrange
        var receivedListener: MoreInformationListener!
        mockMoreInformationBuilder.buildHandler = { listener in
            receivedListener = listener

            return MoreInformationViewControllableMock()
        }

        XCTAssertEqual(mockMoreInformationBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.embedCallCount, 0)

        // Act
        sut.attachMoreInformation()
        sut.attachMoreInformation()

        // Assert
        XCTAssertEqual(mockViewController.embedCallCount, 1)
        XCTAssertEqual(mockMoreInformationBuilder.buildCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === mockViewController)
    }

    func test_routeToAbout_callsBuildAndPresent() {
        // Arrange
        mockAboutBuilder.buildHandler = { _ in RoutingMock() }

        XCTAssertEqual(mockAboutBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.presentCallCount, 0)

        // Act
        sut.routeToAboutApp()

        // Assert
        XCTAssertEqual(mockViewController.presentCallCount, 1)
        XCTAssertEqual(mockAboutBuilder.buildCallCount, 1)
    }

    func test_detachAboutApp_shouldHideViewController_callsViewController() {
        // Arrange
        sut.routeToAboutApp()

        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachAboutApp(shouldHideViewController: true)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }

    func test_detachAboutApp_shouldNotHideViewController_doesNotCallViewController() {
        // Arrange
        sut.routeToAboutApp()

        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachAboutApp(shouldHideViewController: false)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 0)
    }

    func test_routeToSettings() {
        // Arrange
        let mockRouter = RoutingMock(viewControllable: ViewControllableMock())
        mockSettingsBuilder.buildHandler = { listener in
            return mockRouter
        }

        // Act
        sut.routeToSettings()

        // Assert
        XCTAssertEqual(mockSettingsBuilder.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentCallCount, 1)
        XCTAssertTrue(mockViewController.presentArgValues.last?.0 === mockRouter.viewControllable)
    }

    func test_detachSettings_shouldDismissViewController() {
        // Arrange
        sut.routeToSettings()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachSettings(shouldDismissViewController: true)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }

    func test_detachSettings_shouldNotDismissViewController() {
        // Arrange
        sut.routeToSettings()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachSettings(shouldDismissViewController: false)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 0)
    }

    func test_routeToSharing() {
        // Arrange
        let mockViewControllable = ViewControllableMock()
        mockShareBuilder.buildHandler = { listener, items in
            return mockViewControllable
        }

        // Act
        sut.routeToSharing()

        // Assert
        XCTAssertEqual(mockShareBuilder.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentCallCount, 1)
        XCTAssertTrue(mockViewController.presentArgValues.last?.0 === mockViewControllable)
    }

    func test_detachSharing_shouldDismissViewController() {
        // Arrange
        sut.routeToSettings()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachSettings(shouldDismissViewController: true)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }

    func test_detachSharing_shouldNotDismissViewController() {
        // Arrange
        sut.routeToSettings()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachSettings(shouldDismissViewController: false)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 0)
    }

    func test_routeToReceivedNotification() {
        // Arrange
        let mockViewControllable = ViewControllableMock()
        mockReceivedNotificationBuilder.buildHandler = { listener, linkedContent, actionButtonTitle in
            XCTAssertTrue(linkedContent.isEmpty)
            XCTAssertNil(actionButtonTitle)
            return mockViewControllable
        }

        // Act
        sut.routeToReceivedNotification()

        // Assert
        XCTAssertEqual(mockReceivedNotificationBuilder.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentCallCount, 1)
        XCTAssertTrue(mockViewController.presentArgValues.last?.0 === mockViewControllable)
    }

    func test_detachReceivedNotification_shouldDismissViewController() {
        // Arrange
        sut.routeToReceivedNotification()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachReceivedNotification(shouldDismissViewController: true)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }

    func test_detachReceivedNotification_shouldNotDismissViewController() {
        // Arrange
        sut.routeToReceivedNotification()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachReceivedNotification(shouldDismissViewController: false)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 0)
    }

    func test_routeToKeySharing() throws {
        // Arrange
        let mockRouter = RoutingMock()
        mockRouter.viewControllable = ViewControllableMock()
        mockKeySharingBuilder.buildHandler = { _ in
            return mockRouter
        }

        XCTAssertEqual(mockKeySharingBuilder.buildCallCount, 0)

        // Act
        sut.routeToKeySharing()

        // Assert
        XCTAssertEqual(mockKeySharingBuilder.buildCallCount, 1)
        XCTAssertTrue(mockKeySharingBuilder.buildArgValues.first === mockViewController)
        XCTAssertEqual(mockViewController.presentCallCount, 1)

        let presented = try XCTUnwrap(mockViewController.presentArgValues.first)
        XCTAssertTrue(presented.0 === mockRouter.viewControllable)
        XCTAssertTrue(presented.1)
    }

    func test_detachKeySharing_shouldDismissAllPresentedViewControllers() {
        // Arrange
        let mockRouter = RoutingMock()
        mockRouter.viewControllable = ViewControllableMock()
        mockKeySharingBuilder.buildHandler = { _ in
            return mockRouter
        }

        XCTAssertEqual(mockApplicationController.dismissAllPresentedViewControllerCallCount, 0)

        // Act
        sut.routeToKeySharing()
        sut.detachKeySharing(shouldDismissViewController: true)

        // Assert
        XCTAssertEqual(mockApplicationController.dismissAllPresentedViewControllerCallCount, 1)
    }

    func test_routeToRequestTest() {
        // Arrange
        let mockViewControllable = ViewControllableMock()
        mockRequestTestBuilder.buildHandler = { listener in
            mockViewControllable
        }

        // Act
        sut.routeToRequestTest()

        // Assert
        XCTAssertEqual(mockRequestTestBuilder.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentCallCount, 1)
        XCTAssertTrue(mockViewController.presentArgValues.last?.0 === mockViewControllable)
    }

    func test_detachRequestTest_shouldDismissViewController() {
        // Arrange
        sut.routeToRequestTest()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachRequestTest(shouldDismissViewController: true)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }

    func test_detachRequestTest_shouldNotDismissViewController() {
        // Arrange
        sut.routeToRequestTest()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachRequestTest(shouldDismissViewController: false)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 0)
    }

    func test_routeToMessage() {
        // Arrange
        let mockViewControllable = ViewControllableMock()
        mockMessageBuilder.buildHandler = { listener in
            mockViewControllable
        }

        // Act
        sut.routeToMessage()

        // Assert
        XCTAssertEqual(mockMessageBuilder.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentCallCount, 1)
        XCTAssertTrue(mockViewController.presentArgValues.last?.0 === mockViewControllable)
    }

    func test_detachMessage_shouldDismissViewController() {
        // Arrange
        sut.routeToMessage()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachMessage(shouldDismissViewController: true)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }

    func test_detachMessage_shouldNotDismissViewController() {
        // Arrange
        sut.routeToMessage()
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachMessage(shouldDismissViewController: false)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 0)
    }

    func test_routeToEnableSetting_callsBuilderAndPresents() {
        // Arrange
        mockEnableSettingBuilder.buildHandler = { _, _ in ViewControllableMock() }

        XCTAssertEqual(mockEnableSettingBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.presentViewControllerCallCount, 0)

        // Act
        sut.routeToEnableSetting(.enableBluetooth)

        // Assert
        XCTAssertEqual(mockEnableSettingBuilder.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentViewControllerCallCount, 1)
    }

    func test_detachEnableSetting_callsViewControllerWhenRequired() {

        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        sut.detachEnableSetting(shouldDismissViewController: false)

        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        sut.routeToEnableSetting(.enableBluetooth)
        sut.detachEnableSetting(shouldDismissViewController: false)

        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        sut.routeToEnableSetting(.enableBluetooth)
        sut.detachEnableSetting(shouldDismissViewController: true)

        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }

    func test_callWebviewTwice_doesNotPresentTwice() {
        // Arrange
        mockWebviewBuilder.buildHandler = { _, _ in ViewControllableMock() }

        XCTAssertEqual(mockWebviewBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.presentCallCount, 0)

        // Act
        sut.routeToWebview(url: URL(string: "https://coronamelder.nl")!)
        sut.routeToWebview(url: URL(string: "https://coronamelder.nl")!)

        // Assert
        XCTAssertEqual(mockWebviewBuilder.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentViewControllerCallCount, 1)
    }

    func test_detachWebview_callsDismiss() {
        // Arrange
        sut.routeToWebview(url: URL(string: "https://coronamelder.nl")!)

        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        // Act
        sut.detachWebview(shouldDismissViewController: true)

        // Assert
        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }
}

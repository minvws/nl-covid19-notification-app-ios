/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class CardRouterTests: TestCase {
    private var router: CardRouter!
    private var mockViewController = CardViewControllableMock()
    private var mockEnableSettingBuilder = EnableSettingBuildableMock()
    private var mockWebviewBuildable: WebviewBuildableMock!
    private var mockExposureController: ExposureControllingMock!
    
    override func setUp() {
        super.setUp()

        mockViewController = CardViewControllableMock()
        mockEnableSettingBuilder = EnableSettingBuildableMock()
        mockWebviewBuildable = WebviewBuildableMock()
        mockExposureController = ExposureControllingMock()

        router = CardRouter(viewController: mockViewController,
                            enableSettingBuilder: mockEnableSettingBuilder,
                            webviewBuilder: mockWebviewBuildable,
                            exposureController: mockExposureController)
    }

    func test_routeToEnableSetting_buildsAndPresents() {
        var receivedListener: EnableSettingListener!
        var receivedSetting: EnableSetting!
        mockEnableSettingBuilder.buildHandler = { listener, setting in
            receivedListener = listener
            receivedSetting = setting

            return ViewControllableMock()
        }

        XCTAssertEqual(mockEnableSettingBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.presentCallCount, 0)

        router.route(to: .enableBluetooth)

        XCTAssertEqual(mockEnableSettingBuilder.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentCallCount, 1)
        XCTAssert(receivedListener === mockViewController)
        XCTAssertEqual(receivedSetting, .enableBluetooth)
    }

    func test_detachEnableSetting_hideViewController_callsViewController() {
        router.route(to: .enableBluetooth)

        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        router.detachEnableSetting(hideViewController: true)

        XCTAssertEqual(mockViewController.dismissCallCount, 1)
    }

    func test_detachEnableSetting_dontHideViewController_doesNotCallViewController() {
        router.route(to: .enableBluetooth)

        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        router.detachEnableSetting(hideViewController: false)

        XCTAssertEqual(mockViewController.dismissCallCount, 0)
    }

    func test_detachEnableSetting_hideViewController_notPresentedBefore_doesNotCallViewController() {
        XCTAssertEqual(mockViewController.dismissCallCount, 0)

        router.detachEnableSetting(hideViewController: true)

        XCTAssertEqual(mockViewController.dismissCallCount, 0)
    }

    func test_setCardType_forwardToViewController() {
        var receivedCardTypes: [CardType]!
        mockViewController.updateHandler = { receivedCardTypes = $0 }

        XCTAssertEqual(mockViewController.updateCallCount, 0)

        router.types = [.bluetoothOff]

        XCTAssertEqual(mockViewController.updateCallCount, 1)

        guard case .bluetoothOff = receivedCardTypes.first else {
            XCTFail("Expected bluetoothOff cardType")
            return
        }
    }

    func test_routeToURL_shouldPresentWebViewController() {

        let routeToURL = URL(string: "http://www.someurl.com")!
        let presentExpectation = expectation(description: "present")
        let mockCreatedViewController = ViewControllableMock()

        mockWebviewBuildable.buildHandler = { listener, url in
            XCTAssertEqual(url, routeToURL)
            return mockCreatedViewController
        }

        mockViewController.presentViewControllerHandler = { viewController, animated, inNavigationController in
            XCTAssertTrue(viewController === mockCreatedViewController)
            XCTAssertTrue(animated)
            XCTAssertTrue(inNavigationController)
            presentExpectation.fulfill()
        }

        router.route(to: routeToURL)

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertEqual(mockWebviewBuildable.buildCallCount, 1)
        XCTAssertEqual(mockViewController.presentViewControllerCallCount, 1)
    }
    
    func test_routeToRequestExposureNotificationPermission() {
        // Arrange
        XCTAssertEqual(mockExposureController.requestExposureNotificationPermissionCallCount, 0)
        
        // Act
        router.routeToRequestExposureNotificationPermission()
        
        // Assert
        XCTAssertEqual(mockExposureController.requestExposureNotificationPermissionCallCount, 1)
    }

    func test_setTypes_shouldUpdateTypesOnViewController() {
        let newTypes: [CardType] = [.bluetoothOff]

        let updateExpectation = expectation(description: "update")
        mockViewController.updateHandler = { types in
            guard case .bluetoothOff = types.first else {
                XCTFail("viewcontroller not updated with correct card types")
                return
            }
            updateExpectation.fulfill()
        }

        router.types = newTypes

        waitForExpectations(timeout: 2, handler: nil)
    }
}

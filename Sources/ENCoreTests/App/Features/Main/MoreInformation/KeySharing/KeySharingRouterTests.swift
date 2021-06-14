/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import ENCore

class KeySharingRouterTests: TestCase {

    private var sut: KeySharingRouter!
    private var mockKeySharingListener: KeySharingListenerMock!
    private var mockViewController: KeySharingViewControllableMock!
    private var mockShareKeyViaPhoneBuilder: ShareKeyViaPhoneBuildableMock!
    private var mockFeatureFlagController: FeatureFlagControllingMock!
    private var mockShareKeyViaWebsiteBuilder: ShareKeyViaWebsiteBuildableMock!
    
    override func setUp() {
        mockKeySharingListener = KeySharingListenerMock()
        mockViewController = KeySharingViewControllableMock()
        mockShareKeyViaPhoneBuilder = ShareKeyViaPhoneBuildableMock()
        mockFeatureFlagController = FeatureFlagControllingMock()
        mockShareKeyViaWebsiteBuilder = ShareKeyViaWebsiteBuildableMock()
        
        sut = KeySharingRouter(listener: mockKeySharingListener,
                               viewController: mockViewController,
                               shareKeyViaPhoneBuilder: mockShareKeyViaPhoneBuilder,
                               shareKeyViaWebsiteBuilder: mockShareKeyViaWebsiteBuilder,
                               featureFlagController: mockFeatureFlagController)
    }

    func test_viewDidLoad_shouldAutomaticallyRouteToShareViaGGD_ifIndependentKeySharingIsDisabled() throws {
        // Arrange
        let mockRouter = RoutingMock()
        mockRouter.viewControllable = ViewControllableMock()
        mockShareKeyViaPhoneBuilder.buildHandler = { _, _ in
            return mockRouter
        }
        mockFeatureFlagController.isFeatureFlagEnabledHandler = { flag in
            return false
        }
        
        XCTAssertEqual(mockShareKeyViaPhoneBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.pushCallCount, 0)
        
        // Act
        sut.viewDidLoad()
        
        // Assert
        XCTAssertEqual(mockShareKeyViaPhoneBuilder.buildCallCount, 1)
        XCTAssertTrue(mockShareKeyViaPhoneBuilder.buildArgValues.first!.0 === sut)
        XCTAssertFalse(mockShareKeyViaPhoneBuilder.buildArgValues.first!.1)
        XCTAssertEqual(mockViewController.pushCallCount, 1)
        
        let pushedViewController = try XCTUnwrap(mockViewController.pushArgValues.first)
        XCTAssertTrue(pushedViewController.0 === mockRouter.viewControllable)
        XCTAssertFalse(pushedViewController.1)
    }
    
    func test_viewDidLoad_shouldNotAutomaticallyRouteToShareViaGGD_ifIndependentKeySharingIsEnabled() throws {
        // Arrange
        mockFeatureFlagController.isFeatureFlagEnabledHandler = { flag in
            return true
        }
        
        XCTAssertEqual(mockShareKeyViaPhoneBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.pushCallCount, 0)
        
        // Act
        sut.viewDidLoad()
        
        // Assert
        XCTAssertEqual(mockShareKeyViaPhoneBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.pushCallCount, 0)
    }
    
    func test_routeToShareKeyViaGGD_shouldRouteToShareViaGGD() throws {
        // Arrange
        let mockRouter = RoutingMock()
        mockRouter.viewControllable = ViewControllableMock()
        mockShareKeyViaPhoneBuilder.buildHandler = { _, _ in
            return mockRouter
        }
        
        XCTAssertEqual(mockShareKeyViaPhoneBuilder.buildCallCount, 0)
        XCTAssertEqual(mockViewController.pushCallCount, 0)
        
        // Act
        sut.routeToShareKeyViaGGD(animated: true, withBackButton: true)
        
        // Assert
        XCTAssertEqual(mockShareKeyViaPhoneBuilder.buildCallCount, 1)
        XCTAssertTrue(mockShareKeyViaPhoneBuilder.buildArgValues.first!.0 === sut)
        XCTAssertTrue(mockShareKeyViaPhoneBuilder.buildArgValues.first!.1)
        XCTAssertEqual(mockViewController.pushCallCount, 1)
        
        let pushedViewController = try XCTUnwrap(mockViewController.pushArgValues.first)
        XCTAssertTrue(pushedViewController.0 === mockRouter.viewControllable)
        XCTAssertTrue(pushedViewController.1)
    }
    
    func test_keySharingWantsDismissal_shouldCallListener() {
        // Arrange
        XCTAssertEqual(mockKeySharingListener.keySharingWantsDismissalCallCount, 0)
        
        // Act
        sut.keySharingWantsDismissal(shouldDismissViewController: true)
        
        // Assert
        XCTAssertEqual(mockKeySharingListener.keySharingWantsDismissalCallCount, 1)
        XCTAssertTrue(mockKeySharingListener.keySharingWantsDismissalArgValues.first!)
    }
    
    func test_shareKeyViaPhoneWantsDismissal_shouldCallListener() {
        // Arrange
        XCTAssertEqual(mockKeySharingListener.keySharingWantsDismissalCallCount, 0)
        
        // Act
        sut.shareKeyViaPhoneWantsDismissal(shouldDismissViewController: true)
        
        // Assert
        XCTAssertEqual(mockKeySharingListener.keySharingWantsDismissalCallCount, 1)
        XCTAssertTrue(mockKeySharingListener.keySharingWantsDismissalArgValues.first!)
    }

}

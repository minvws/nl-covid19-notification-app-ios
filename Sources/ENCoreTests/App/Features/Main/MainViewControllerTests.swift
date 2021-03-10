/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class MainViewControllerTests: TestCase {
    private var viewController: MainViewController!
    private let router = MainRoutingMock()
    private let statusBuilder = StatusBuildableMock()
    private let moreInformationBuilder = MoreInformationBuildableMock()
    private let exposureController = ExposureControllingMock()
    private let exposureStateStream = ExposureStateStreamingMock()
    private var mockPauseController = PauseControllingMock()
    private var mockUserNotificationCenter = UserNotificationCenterMock()
    private let alertControllerBuilder = AlertControllerBuildableMock()
    
    override func setUp() {
        super.setUp()

        viewController = MainViewController(theme: theme,
                                            exposureController: exposureController,
                                            exposureStateStream: exposureStateStream,
                                            userNotificationCenter: mockUserNotificationCenter,
                                            pauseController: mockPauseController,
                                            alertControllerBuilder: alertControllerBuilder)
        viewController.router = router
    }

    // MARK: - MoreInformationListener

    func test_moreInformationRequestsAbout_callsRouter() {
        XCTAssertEqual(router.routeToAboutAppCallCount, 0)

        viewController.moreInformationRequestsAbout()

        XCTAssertEqual(router.routeToAboutAppCallCount, 1)
    }

    func test_moreInformationRequestsReceivedNotification_callsRouter() {
        XCTAssertEqual(router.routeToReceivedNotificationCallCount, 0)

        viewController.moreInformationRequestsReceivedNotification()

        XCTAssertEqual(router.routeToReceivedNotificationCallCount, 1)
    }

    func test_moreInformationRequestsInfected_callsRouter() {
        XCTAssertEqual(router.routeToInfectedCallCount, 0)

        viewController.moreInformationRequestsInfected()

        XCTAssertEqual(router.routeToInfectedCallCount, 1)
    }

    func test_moreInformationRequestsRequestTest_callsRouter() {
        XCTAssertEqual(router.routeToRequestTestCallCount, 0)

        viewController.moreInformationRequestsRequestTest()

        XCTAssertEqual(router.routeToRequestTestCallCount, 1)
    }

    func test_viewDidLoad_callsRouterInRightOrder() {
        XCTAssertEqual(router.attachStatusCallCount, 0)
        XCTAssertEqual(router.attachMoreInformationCallCount, 0)

        var callCountIndex = 0
        var attachStatusCallCountIndex = 0
        var attachMoreInformationCallCountIndex = 0

        router.attachStatusHandler = { _ in
            callCountIndex += 1
            attachStatusCallCountIndex = callCountIndex
        }

        router.attachMoreInformationHandler = {
            callCountIndex += 1
            attachMoreInformationCallCountIndex = callCountIndex
        }

        _ = viewController.view

        XCTAssertEqual(router.attachStatusCallCount, 1)
        XCTAssertEqual(router.attachMoreInformationCallCount, 1)
        XCTAssertEqual(attachStatusCallCountIndex, 1)
        XCTAssertEqual(attachMoreInformationCallCountIndex, 2)
    }

    func test_handleButtonAction_explainRisk() {
        XCTAssertEqual(router.routeToMessageCallCount, 0)
        viewController.handleButtonAction(.explainRisk(Date()))
        XCTAssertEqual(router.routeToMessageCallCount, 1)
    }

    func test_handleButtonAction_removeNotification_confirmShouldCallExposureController() {
        var createdAlertController: UIAlertController?
        var actionHandlers = [((UIAlertAction) -> Void)]()
        
        alertControllerBuilder.buildAlertControllerHandler = { title, message, prefferedStyle in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: prefferedStyle)
            createdAlertController = alertController
            return alertController
        }
        
        alertControllerBuilder.buildAlertActionHandler = { title, style, handler in
            actionHandlers.append(handler!)
            return UIAlertAction(title: title, style: style, handler: handler)
        }
        
        XCTAssertEqual(alertControllerBuilder.buildAlertControllerCallCount, 0)
        XCTAssertEqual(exposureController.confirmExposureNotificationCallCount, 0)
        
        viewController.handleButtonAction(.removeNotification("SomeTitle"))
        
        // Execute the last action in the alert, this should call exposureController.confirmExposureNotification()
        actionHandlers.last?(UIAlertAction())
        
        XCTAssertEqual(alertControllerBuilder.buildAlertControllerCallCount, 1)
        XCTAssertEqual(exposureController.confirmExposureNotificationCallCount, 1)
        XCTAssertEqual(createdAlertController?.title, "SomeTitle")
        XCTAssertEqual(createdAlertController?.message, "Are you sure you want to delete this notification? You won\'t be able to find the date in the app anymore. So remember it well.")
        XCTAssertEqual(createdAlertController?.preferredStyle, .alert)
    }

    func test_enableSettingShouldDismiss_callsRouter() {
        var shouldDismissViewController: Bool!
        router.detachEnableSettingHandler = { shouldDismissViewController = $0 }

        XCTAssertEqual(router.detachEnableSettingCallCount, 0)

        viewController.enableSettingRequestsDismiss(shouldDismissViewController: true)

        XCTAssertEqual(router.detachEnableSettingCallCount, 1)
        XCTAssertTrue(shouldDismissViewController)
    }

    func test_enableSettingDidCompleteAction_callsRouter() {
        var shouldDismissViewController: Bool!
        router.detachEnableSettingHandler = { shouldDismissViewController = $0 }

        XCTAssertEqual(router.detachEnableSettingCallCount, 0)

        viewController.enableSettingDidTriggerAction()

        XCTAssertEqual(router.detachEnableSettingCallCount, 1)
        XCTAssertTrue(shouldDismissViewController)
    }
}

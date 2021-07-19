/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class RootViewControllerTests: TestCase {
    private var mock: RootViewControllableMock!
    private var viewController: RootViewController!
    private var emptyViewController: ViewController!
    private let router = RootRoutingMock()

    override func setUp() {
        super.setUp()

        viewController = RootViewController(theme: theme)
        viewController.router = router

        emptyViewController = ViewController(theme: theme)
        emptyViewController.view.backgroundColor = theme.colors.ok

        mock = RootViewControllableMock(uiviewController: viewController, router: router)
    }

    func test_didCompleteOnboarding_callsDetachOnboardingAndRouteToMain() {
        XCTAssertEqual(router.detachOnboardingAndRouteToMainCallCount, 0)

        viewController.didCompleteOnboarding()

        XCTAssertEqual(router.detachOnboardingAndRouteToMainCallCount, 1)
    }

    func test_messageWantsDismissal_callDismissViewController() {
        XCTAssertEqual(router.detachMessageCallCount, 0)

        viewController.messageWantsDismissal(shouldDismissViewController: true)

        XCTAssertEqual(router.detachMessageCallCount, 1)
    }

    func test_callGGDWantsDismissal_callDismissViewController() {
        XCTAssertEqual(router.detachCallGGDCallCount, 0)

        viewController.callGGDWantsDismissal(shouldDismissViewController: true)

        XCTAssertEqual(router.detachCallGGDCallCount, 1)
    }

    func test_didCompleteConsent() {
        XCTAssertEqual(router.scheduleTasksCallCount, 0)

        viewController.didCompleteConsent()

        XCTAssertEqual(router.scheduleTasksCallCount, 1)
    }

    func test_endOfLifeRequestsRedirect() {
        XCTAssertEqual(router.routeToWebviewCallCount, 0)

        let mockUrl = URL(string: "http://someurl.com")

        viewController.endOfLifeRequestsRedirect(to: mockUrl!)

        XCTAssertEqual(router.routeToWebviewCallCount, 1)
    }

    func test_webviewRequestsDismissal() {
        XCTAssertEqual(router.detachWebviewCallCount, 0)

        viewController.webviewRequestsDismissal(shouldHideViewController: true)

        XCTAssertEqual(router.detachWebviewCallCount, 1)
    }

    func test_developerMenuRequestsOnboardingFlow() {
        XCTAssertEqual(router.routeToOnboardingCallCount, 0)

        viewController.developerMenuRequestsOnboardingFlow()

        XCTAssertEqual(router.routeToOnboardingCallCount, 1)
    }

    func test_developerMenuRequestUpdateOperatingSystem() {
        XCTAssertEqual(router.routeToUpdateOperatingSystemCallCount, 0)

        viewController.developerMenuRequestUpdateOperatingSystem()

        XCTAssertEqual(router.routeToUpdateOperatingSystemCallCount, 1)
    }

    func test_developerMenuRequestUpdateApp() {
        XCTAssertEqual(router.routeToUpdateAppCallCount, 0)

        viewController.developerMenuRequestUpdateApp(appStoreURL: "mock",
                                                     minimumVersionMessage: "mock")

        XCTAssertEqual(router.routeToUpdateAppCallCount, 1)
    }
}

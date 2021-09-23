/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class AboutViewControllerTests: TestCase {
    private var viewController: AboutViewController!
    private var router = AboutRoutingMock()
    private let listener = AboutListenerMock()

    override func setUp() {
        super.setUp()

        viewController = AboutViewController(listener: listener,
                                             theme: theme)

        viewController.router = router
    }

    func test_presentationControllerDidDismiss_callsListener() {
        var shouldDismissViewController: Bool!
        listener.aboutRequestsDismissalHandler = { shouldDismissViewController = $0 }

        XCTAssertEqual(listener.aboutRequestsDismissalCallCount, 0)

        let presentationController = UIPresentationController(presentedViewController: UIViewController(),
                                                              presenting: nil)
        viewController.presentationControllerDidDismiss(presentationController)

        XCTAssertEqual(listener.aboutRequestsDismissalCallCount, 1)
        XCTAssertNotNil(shouldDismissViewController)
        XCTAssertFalse(shouldDismissViewController)
    }

    func test_didTapClose_callsListener() {
        var shouldDismissViewController: Bool!
        listener.aboutRequestsDismissalHandler = { shouldDismissViewController = $0 }

        XCTAssertEqual(listener.aboutRequestsDismissalCallCount, 0)

        viewController.didTapClose()

        XCTAssertEqual(listener.aboutRequestsDismissalCallCount, 1)
        XCTAssertNotNil(shouldDismissViewController)
        XCTAssertTrue(shouldDismissViewController)
    }

    func test_aboutOverviewRequestsRouteTo_callsRouter() {

        XCTAssertEqual(router.routeToAboutEntryCallCount, 0)

        let entry = AboutEntry.rate(title: "dummy")
        viewController.aboutOverviewRequestsRouteTo(entry: entry)

        XCTAssertEqual(router.routeToAboutEntryCallCount, 1)
    }

    func test_aboutOverviewRequestsRouteToAppInformation_callsRouter() {

        XCTAssertEqual(router.routeToAppInformationCallCount, 0)

        viewController.aboutOverviewRequestsRouteToAppInformation()

        XCTAssertEqual(router.routeToAppInformationCallCount, 1)
    }

    func test_aboutOverviewRequestsRouteToTechnicalInformation_callsRouter() {

        XCTAssertEqual(router.routeToTechnicalInformationCallCount, 0)

        viewController.aboutOverviewRequestsRouteToTechnicalInformation()

        XCTAssertEqual(router.routeToTechnicalInformationCallCount, 1)
    }

    func test_helpDetailRequestsDismissal_callsRouter() {

        XCTAssertEqual(router.detachHelpQuestionCallCount, 0)

        viewController.helpDetailRequestsDismissal(shouldDismissViewController: true)

        XCTAssertEqual(router.detachHelpQuestionCallCount, 1)
    }

    func test_helpDetailRequestRedirect_callsRouter() {

        XCTAssertEqual(router.routeToAboutEntryCallCount, 0)

        let content = AboutEntry.rate(title: "dummy")

        viewController.helpDetailRequestRedirect(to: content)

        XCTAssertEqual(router.routeToAboutEntryCallCount, 1)
    }

    func test_receivedNotificationWantsDismissal_callsRouter() {

        XCTAssertEqual(router.detachReceivedNotificationCallCount, 0)

        viewController.receivedNotificationWantsDismissal(shouldDismissViewController: true)

        XCTAssertEqual(router.detachReceivedNotificationCallCount, 1)
    }

    func test_receivedNotificationRequestRedirect_callsRouter() {

        XCTAssertEqual(router.routeToAboutEntryCallCount, 0)

        let content = AboutEntry.rate(title: "dummy")

        viewController.receivedNotificationRequestRedirect(to: content)

        XCTAssertEqual(router.routeToAboutEntryCallCount, 1)
    }

    func test_appInformationRequestsToTechnicalInformation_callsRouter() {

        XCTAssertEqual(router.routeToTechnicalInformationCallCount, 0)

        viewController.appInformationRequestsToTechnicalInformation()

        XCTAssertEqual(router.routeToTechnicalInformationCallCount, 1)
    }

    func test_appInformationRequestRedirect_callsRouter() {

        XCTAssertEqual(router.routeToAboutEntryCallCount, 0)

        let content = AboutEntry.rate(title: "dummy")

        viewController.appInformationRequestRedirect(to: content)

        XCTAssertEqual(router.routeToAboutEntryCallCount, 1)
    }

    func test_technicalInformationRequestsToAppInformation_callsRouter() {

        XCTAssertEqual(router.routeToAppInformationCallCount, 0)

        viewController.technicalInformationRequestsToAppInformation()

        XCTAssertEqual(router.routeToAppInformationCallCount, 1)
    }

    func test_technicalInformationRequestRedirect_callsRouter() {

        XCTAssertEqual(router.routeToAboutEntryCallCount, 0)

        let content = AboutEntry.rate(title: "dummy")

        viewController.technicalInformationRequestRedirect(to: content)

        XCTAssertEqual(router.routeToAboutEntryCallCount, 1)
    }
}

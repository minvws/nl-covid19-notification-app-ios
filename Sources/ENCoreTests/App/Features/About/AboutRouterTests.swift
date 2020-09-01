/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class AboutRouterTests: TestCase {
    private let viewController = AboutViewControllableMock()
    private let aboutOverviewBuilder = AboutOverviewBuildableMock()
    private let helpDetailBuilder = HelpDetailBuildableMock()
    private let appInformationBuilder = AppInformationBuildableMock()
    private let technicalInformationBuilder = TechnicalInformationBuildableMock()
    private let webviewBuilder = WebviewBuildableMock()
    private let receivedNotificationBuilder = ReceivedNotificationBuildableMock()
    private let exposureController = ExposureControllingMock()
    private var router: AboutRouter!

    override func setUp() {
        super.setUp()

        router = AboutRouter(viewController: viewController, aboutOverviewBuilder: aboutOverviewBuilder, helpDetailBuilder: helpDetailBuilder, appInformationBuilder: appInformationBuilder, technicalInformationBuilder: technicalInformationBuilder, webviewBuilder: webviewBuilder, receivedNotificationBuilder: receivedNotificationBuilder, exposureController: exposureController)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    func test_routeToOverview_callsBuildAndPush() {
        var receivedListener: AboutOverviewListener!
        aboutOverviewBuilder.buildHandler = { listener in
            receivedListener = listener
            return ViewControllableMock()
        }

        XCTAssertEqual(aboutOverviewBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToOverview()

        XCTAssertEqual(aboutOverviewBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_routeToOverview_callsBuildAndPushOnce() {
        var receivedListener: AboutOverviewListener!
        aboutOverviewBuilder.buildHandler = { listener in
            receivedListener = listener
            return ViewControllableMock()
        }

        XCTAssertEqual(aboutOverviewBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToOverview()
        router.routeToOverview()

        XCTAssertEqual(aboutOverviewBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_routeToAboutEntry_withQuestionType_callsBuildAndPush() {
        var receivedListener: HelpDetailListener!
        helpDetailBuilder.buildHandler = { listener, _, _ in
            receivedListener = listener
            return ViewControllableMock()
        }

        XCTAssertEqual(helpDetailBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToAboutEntry(entry: .question(HelpQuestion(question: "question", answer: "answer")))

        XCTAssertEqual(helpDetailBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_routeToAboutEntry_withLinkType_callsBuildAndPush() {
        var receivedListener: WebviewListener!
        webviewBuilder.buildHandler = { listener, _ in
            receivedListener = listener
            return ViewControllableMock()
        }

        XCTAssertEqual(webviewBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToAboutEntry(entry: .link(title: "some title", link: "http://coronamelder.nl"))

        XCTAssertEqual(webviewBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_routeToAboutEntry_withLinkType_invalidLink_doesNotCallsBuildAndPush() {
        XCTAssertEqual(webviewBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToAboutEntry(entry: .link(title: "some title", link: "htl:\\"))

        XCTAssertEqual(webviewBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)
    }

    func test_routeToAboutEntry_withNotificationExplanation_callsBuildAndPush() {
        var receivedListener: ReceivedNotificationListener!
        receivedNotificationBuilder.buildHandler = { listener in
            receivedListener = listener
            return ViewControllableMock()
        }

        XCTAssertEqual(receivedNotificationBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToAboutEntry(entry: .notificationExplanation(title: "Title", linkedContent: []))

        XCTAssertEqual(receivedNotificationBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_routeToAppInformation_callsPush() {
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToAppInformation()

        XCTAssertEqual(viewController.pushCallCount, 1)
    }

    func test_routeToTechnicalInformation_callsPush() {
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToTechnicalInformation()

        XCTAssertEqual(viewController.pushCallCount, 1)
    }
}

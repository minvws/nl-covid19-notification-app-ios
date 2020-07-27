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

    private var router: AboutRouter!

    override func setUp() {
        super.setUp()

        router = AboutRouter(viewController: viewController, aboutOverviewBuilder: aboutOverviewBuilder, helpDetailBuilder: helpDetailBuilder, appInformationBuilder: appInformationBuilder, technicalInformationBuilder: technicalInformationBuilder)
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

    func test_detachOverview_dismissViewController() {
        router.routeToOverview()

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachAboutOverview(shouldDismissViewController: true)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToHelpDetail_callsBuildAndPush() {
        var receivedListener: HelpDetailListener!
        helpDetailBuilder.buildHandler = { listener, _, _ in
            receivedListener = listener
            return ViewControllableMock()
        }

        XCTAssertEqual(helpDetailBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToHelpQuestion(question: HelpQuestion(theme: theme, question: "question", answer: "answer"))

        XCTAssertEqual(helpDetailBuilder.buildCallCount, 1)
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

        router.routeToTechninalInformation()

        XCTAssertEqual(viewController.pushCallCount, 1)
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

@testable import ENCore
import Foundation
import XCTest

final class HelpRouterTests: TestCase {
    private let viewController = HelpViewControllableMock()
    private let helpOverviewBuilder = HelpOverviewBuildableMock()
    private let helpDetailBuilder = HelpDetailBuildableMock()
    private let receivedNotificationBuilder = ReceivedNotificationBuildableMock()

    private var router: HelpRouter!

    override func setUp() {
        super.setUp()

        router = HelpRouter(viewController: viewController, helpOverviewBuilder: helpOverviewBuilder, helpDetailBuilder: helpDetailBuilder, receivedNotificationBuilder: receivedNotificationBuilder)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    func test_routeToOverview_callsBuildAndPush() {
        var receivedListener: HelpOverviewListener!
        helpOverviewBuilder.buildHandler = { listener, _ in
            receivedListener = listener
            return ViewControllableMock()
        }

        XCTAssertEqual(helpOverviewBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToOverview(shouldShowEnableAppButton: true)

        XCTAssertEqual(helpOverviewBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_routeToOverview_callsBuildAndPushOnce() {
        var receivedListener: HelpOverviewListener!
        helpOverviewBuilder.buildHandler = { listener, _ in
            receivedListener = listener
            return ViewControllableMock()
        }

        XCTAssertEqual(helpOverviewBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)

        router.routeToOverview(shouldShowEnableAppButton: true)
        router.routeToOverview(shouldShowEnableAppButton: true)

        XCTAssertEqual(helpOverviewBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_routeToQuestion_twice_callsRemoveCleanNavigationStackIfNeeded() {
        XCTAssertEqual(helpDetailBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.pushCallCount, 0)
        XCTAssertEqual(viewController.cleanNavigationStackIfNeededCallCount, 0)

        router.routeTo(entry: HelpOverviewEntry.question(HelpQuestion(question: "question", answer: "answer")), shouldShowEnableAppButton: true)

        XCTAssertEqual(helpDetailBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertEqual(viewController.cleanNavigationStackIfNeededCallCount, 1)

        router.routeTo(entry: HelpOverviewEntry.question(HelpQuestion(question: "another question", answer: "another answer")), shouldShowEnableAppButton: true)

        XCTAssertEqual(helpDetailBuilder.buildCallCount, 2)
        XCTAssertEqual(viewController.pushCallCount, 2)
        XCTAssertEqual(viewController.cleanNavigationStackIfNeededCallCount, 2)
    }
}

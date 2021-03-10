/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class MainRouterTests: XCTestCase {
    private let viewController = MainViewControllableMock()
    private let statusBuilder = StatusBuildableMock()
    private let moreInformationBuilder = MoreInformationBuildableMock()
    private let aboutBuilder = AboutBuildableMock()
    private let shareBuilder = ShareSheetBuildableMock()
    private let receivedNotificationBuilder = ReceivedNotificationBuildableMock()
    private let requestTestBuilder = RequestTestBuildableMock()
    private let infectedBuilder = InfectedBuildableMock()
    private let messageBuilder = MessageBuildableMock()
    private let enableSettingBuilder = EnableSettingBuildableMock()
    private let webviewBuilder = WebviewBuildableMock()
    private let settingsBuilder = SettingsBuildableMock()

    private var router: MainRouter!

    override func setUp() {
        super.setUp()

        router = MainRouter(viewController: viewController,
                            statusBuilder: statusBuilder,
                            moreInformationBuilder: moreInformationBuilder,
                            aboutBuilder: aboutBuilder,
                            shareBuilder: shareBuilder,
                            receivedNotificationBuilder: receivedNotificationBuilder,
                            requestTestBuilder: requestTestBuilder,
                            infectedBuilder: infectedBuilder,
                            messageBuilder: messageBuilder,
                            enableSettingBuilder: enableSettingBuilder,
                            webviewBuilder: webviewBuilder,
                            settingsBuilder: settingsBuilder)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    func test_attachStatus_callsBuildAndEmbed() {
        var receivedListener: StatusListener!
        var receivedAnchor: NSLayoutYAxisAnchor!
        statusBuilder.buildHandler = { listener, anchor in
            receivedListener = listener
            receivedAnchor = anchor

            return StatusViewControllableMock()
        }

        XCTAssertEqual(statusBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        let anchor = NSLayoutYAxisAnchor()
        router.attachStatus(topAnchor: anchor)

        XCTAssertEqual(viewController.embedCallCount, 1)
        XCTAssertEqual(statusBuilder.buildCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
        XCTAssert(receivedAnchor === anchor)
    }

    func test_callAttachStatusTwice_callsBuildAndEmbedOnce() {
        var receivedListener: StatusListener!
        var receivedAnchor: NSLayoutYAxisAnchor!
        statusBuilder.buildHandler = { listener, anchor in
            receivedListener = listener
            receivedAnchor = anchor

            return StatusViewControllableMock()
        }

        XCTAssertEqual(statusBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        let anchor = NSLayoutYAxisAnchor()
        router.attachStatus(topAnchor: anchor)
        router.attachStatus(topAnchor: NSLayoutYAxisAnchor())

        XCTAssertEqual(viewController.embedCallCount, 1)
        XCTAssertEqual(statusBuilder.buildCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
        XCTAssert(receivedAnchor === anchor)
    }

    func test_attachMoreInformation_callsBuildAndEmbed() {
        var receivedListener: MoreInformationListener!
        moreInformationBuilder.buildHandler = { listener in
            receivedListener = listener

            return MoreInformationViewControllableMock()
        }

        XCTAssertEqual(moreInformationBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.attachMoreInformation()

        XCTAssertEqual(viewController.embedCallCount, 1)
        XCTAssertEqual(moreInformationBuilder.buildCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_callAttachMoreInformationTwice_callsBuildAndEmbedOnce() {
        var receivedListener: MoreInformationListener!
        moreInformationBuilder.buildHandler = { listener in
            receivedListener = listener

            return MoreInformationViewControllableMock()
        }

        XCTAssertEqual(moreInformationBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.attachMoreInformation()
        router.attachMoreInformation()

        XCTAssertEqual(viewController.embedCallCount, 1)
        XCTAssertEqual(moreInformationBuilder.buildCallCount, 1)
        XCTAssertNotNil(receivedListener)
        XCTAssert(receivedListener === viewController)
    }

    func test_routeToAbout_callsBuildAndPresent() {
        aboutBuilder.buildHandler = { _ in RoutingMock() }

        XCTAssertEqual(aboutBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)

        router.routeToAboutApp()

        XCTAssertEqual(viewController.presentCallCount, 1)
        XCTAssertEqual(aboutBuilder.buildCallCount, 1)
    }

    func test_detachHelp_shouldHideViewController_callsViewController() {
        router.routeToAboutApp()

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachAboutApp(shouldHideViewController: true)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_detachAboutApp_shouldNotHideViewController_doesNotCallViewController() {
        router.routeToAboutApp()

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachAboutApp(shouldHideViewController: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)
    }

    func test_routeToEnableSetting_callsBuilderAndPresents() {
        enableSettingBuilder.buildHandler = { _, _ in ViewControllableMock() }

        XCTAssertEqual(enableSettingBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentViewControllerCallCount, 0)

        router.routeToEnableSetting(.enableBluetooth)

        XCTAssertEqual(enableSettingBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentViewControllerCallCount, 1)
    }

    func test_detachEnableSetting_callsViewControllerWhenRequired() {
        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachEnableSetting(shouldDismissViewController: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.routeToEnableSetting(.enableBluetooth)
        router.detachEnableSetting(shouldDismissViewController: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.routeToEnableSetting(.enableBluetooth)
        router.detachEnableSetting(shouldDismissViewController: true)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_callWebviewTwice_doesNotPresentTwice() {
        webviewBuilder.buildHandler = { _, _ in ViewControllableMock() }

        XCTAssertEqual(webviewBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)

        router.routeToWebview(url: URL(string: "https://coronamelder.nl")!)
        router.routeToWebview(url: URL(string: "https://coronamelder.nl")!)

        XCTAssertEqual(webviewBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentViewControllerCallCount, 1)
    }

    func test_detachWebview_callsDismiss() {
        router.routeToWebview(url: URL(string: "https://coronamelder.nl")!)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachWebview(shouldDismissViewController: true)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToSettings() {

        let mockRouter = RoutingMock(viewControllable: ViewControllableMock())
        settingsBuilder.buildHandler = { listener in
            return mockRouter
        }

        router.routeToSettings()

        XCTAssertEqual(settingsBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
        XCTAssertTrue(viewController.presentArgValues.last?.0 === mockRouter.viewControllable)
    }
}

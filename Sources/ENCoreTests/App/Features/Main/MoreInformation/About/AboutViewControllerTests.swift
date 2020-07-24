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
    private let listener = AboutListenerMock()
    private let webBuilder = WebBuildableMock()

    override func setUp() {
        super.setUp()

        viewController = AboutViewController(listener: listener,
                                             theme: theme,
                                             webBuilder: webBuilder)
    }

    func test_viewDidLoad_callsBuildAndEmbedWebView() {
        webBuilder.buildHandler = { _, _ in WebViewControllableMock() }

        XCTAssertEqual(webBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.children.count, 0)

        _ = viewController.view

        XCTAssertEqual(webBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.children.count, 1)
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
}

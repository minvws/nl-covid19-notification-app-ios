/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import SnapshotTesting
import XCTest

final class MessageViewControllerTests: TestCase {
    private var viewController: MessageViewController!
    private let listern = MessageListenerMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        viewController = MessageViewController(listener: listern,
                                               theme: theme,
                                               message: MessageViewController.Message(title: "Title",
                                                                                      body: "Body"))
    }

    // MARK: - Tests

    func testSnapshotMessageViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listern.messageWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listern.messageWantsDismissalCallCount, 1)
    }
}

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

final class ReceivedNotificationViewControllerTests: XCTestCase {
    private var viewController: ReceivedNotificationViewController!
    private let listern = ReceivedNotificationListenerMock()

    override func setUp() {
        super.setUp()

        let theme = ENTheme()
        SnapshotTesting.record = false

        viewController = ReceivedNotificationViewController(listener: listern, theme: theme)
    }

    // MARK: - Tests

    func testSnapshotReceivedNotificationViewController() {
        assertSnapshot(matching: viewController, as: .image())
    }

    func testPresentationControllerDidDismissCallsListener() {
        listern.receivedNotificationWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listern.receivedNotificationWantsDismissalCallCount, 1)
    }
}

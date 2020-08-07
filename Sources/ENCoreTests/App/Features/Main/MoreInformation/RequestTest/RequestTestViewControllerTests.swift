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

final class RequestTestViewControllerTests: TestCase {
    private var viewController: RequestTestViewController!
    private let listern = RequestTestListenerMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        viewController = RequestTestViewController(listener: listern, theme: theme)
    }

    // MARK: - Tests

    func testSnapshotRequestTestViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listern.requestTestWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listern.requestTestWantsDismissalCallCount, 1)
    }
}

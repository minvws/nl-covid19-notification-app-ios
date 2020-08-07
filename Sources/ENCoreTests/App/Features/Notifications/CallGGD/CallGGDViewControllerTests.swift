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

final class CallGGDControllerTests: TestCase {
    private var viewController: CallGGDViewController!
    private let listern = CallGGDListenerMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        viewController = CallGGDViewController(listener: listern, theme: theme)
    }

    // MARK: - Tests

    func testSnapshotCallGGDViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listern.callGGDWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listern.callGGDWantsDismissalCallCount, 1)
    }
}

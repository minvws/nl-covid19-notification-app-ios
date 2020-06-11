/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import Foundation
import XCTest
import SnapshotTesting

final class StatusViewControllerTests: XCTestCase {
    private var viewController: StatusViewController!
    private let router = StatusRoutingMock()

    override func setUp() {
        super.setUp()

        viewController = StatusViewController(listener: StatusListenerMock())
        viewController.router = router
    }

    func testSnapshotActive() {
        viewController.update(with: .active)
        assertSnapshot(matching: viewController, as: .image(), record: true)
    }

    func testSnapshotNotified() {
        viewController.update(with: .notified)
        assertSnapshot(matching: viewController, as: .image(), record: true)
    }
}

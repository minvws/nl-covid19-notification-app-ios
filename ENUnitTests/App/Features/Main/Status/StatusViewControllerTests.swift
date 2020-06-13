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
import Combine

final class StatusViewControllerTests: XCTestCase {
    private var exposureStateStream = ExposureStateStreamingMock()
    private var viewController: StatusViewController!
    private let router = StatusRoutingMock()

    override func setUp() {
        super.setUp()

        SnapshotTesting.record = true

        viewController = StatusViewController(exposureStateStream: exposureStateStream, listener: StatusListenerMock())
        viewController.router = router
    }

    func testSnapshotActive() {
        exposureStateStream.exposureStatus = Just(.active).eraseToAnyPublisher()
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        assertSnapshot(matching: viewController, as: .image())
    }

    func testSnapshotNotified() {
        exposureStateStream.exposureStatus = Just(.notified).eraseToAnyPublisher()
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        assertSnapshot(matching: viewController, as: .image())
    }
}

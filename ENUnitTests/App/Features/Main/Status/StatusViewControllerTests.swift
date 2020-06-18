/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import EN
import Foundation
import SnapshotTesting
import XCTest

final class StatusViewControllerTests: XCTestCase {
    private var exposureStateStream = ExposureStateStreamingMock()
    private var viewController: StatusViewController!
    private let router = StatusRoutingMock()

    override func setUp() {
        super.setUp()

        let theme = ENTheme()

        SnapshotTesting.record = false

        viewController = StatusViewController(exposureStateStream: exposureStateStream, listener: StatusListenerMock(), theme: theme, topAnchor: nil)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.router = router
    }

    func testSnapshotActive() {
        set(activeState: .active)
        assertSnapshot(matching: viewController, as: .image())
    }

    func testSnapshotNotified() {
        set(notified: true)
        assertSnapshot(matching: viewController, as: .image())
    }

    func testSnapshotNotifiedInactive() {
        set(activeState: .inactive(.noRecentNotificationUpdates), notified: true)
        assertSnapshot(matching: viewController, as: .image())
    }

    // MARK: - Private

    private func set(activeState: ExposureActiveState = .active, notified: Bool = false) {
        let notifiedState: ExposureNotificationState = notified ? .notified(Date()) : .notNotified
        let state = ExposureState(notifiedState: notifiedState, activeState: activeState)

        exposureStateStream.exposureState = Just(state).eraseToAnyPublisher()
    }
}

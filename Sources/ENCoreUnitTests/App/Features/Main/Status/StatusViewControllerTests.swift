/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
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

        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593200000)

        SnapshotTesting.diffTool = "ksdiff"
        SnapshotTesting.record = false

        viewController = StatusViewController(exposureStateStream: exposureStateStream, listener: StatusListenerMock(), theme: theme, topAnchor: nil)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.router = router
    }

    func test_snapshot_active_not_notified() {
        set(activeState: .active, notified: false)
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_snapshot_active_notified() {
        set(activeState: .active, notified: true)
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_snapshot_active_notified_days_ago() {
        DateTimeTestingOverrides.overriddenCurrentDate = Date(timeIntervalSince1970: 1593000030)
        set(activeState: .active, notified: true)
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_snapshot_inactive_notified() {
        set(activeState: .inactive(.paused), notified: true)
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_snapshot_inactive_not_notified() {
        set(activeState: .inactive(.paused), notified: false)
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_snapshot_authorized_denied_notNotified() {
        set(activeState: .authorizationDenied, notified: true)
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_snapshot_authorized_denied_notified() {
        set(activeState: .authorizationDenied, notified: false)
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_snapshot_not_authorized_notified() {
        set(activeState: .notAuthorized, notified: true)
        assertSnapshot(matching: viewController, as: .image())
    }

    func test_snapshot_not_authorized_not_notified() {
        set(activeState: .notAuthorized, notified: false)
        assertSnapshot(matching: viewController, as: .image())
    }

    // MARK: - Private

    private func set(activeState: ExposureActiveState, notified: Bool) {
        let notifiedState: ExposureNotificationState = notified ? .notified(Date(timeIntervalSince1970: 1593262397)) : .notNotified
        let state = ExposureState(notifiedState: notifiedState, activeState: activeState)

        exposureStateStream.exposureState = Just(state).eraseToAnyPublisher()
    }
}

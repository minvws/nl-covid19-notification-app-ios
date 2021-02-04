/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import ENFoundation
import Foundation
import SnapshotTesting
import XCTest

final class SettingsOverviewViewControllerTests: TestCase {
    private var sut: SettingsOverviewViewController!
    private var mockListener: SettingsOverviewListenerMock!
    private var mockPauseController: PauseControllingMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockPushNotificationStream: PushNotificationStreamingMock!

    private let pushNotificationSubject = PassthroughSubject<UNNotification, Never>()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        mockListener = SettingsOverviewListenerMock()
        mockExposureDataController = ExposureDataControllingMock()
        mockPauseController = PauseControllingMock()
        mockPushNotificationStream = PushNotificationStreamingMock()

        mockPushNotificationStream.foregroundNotificationStream = pushNotificationSubject.eraseToAnyPublisher()

        mockExposureDataController.pauseEndDatePublisher = Just(nil).eraseToAnyPublisher()

        mockPauseController.getPauseCountdownStringHandler = { _, _ in
            return NSAttributedString(string: "Some mock countdown string")
        }

        sut = SettingsOverviewViewController(listener: mockListener,
                                             theme: theme,
                                             exposureDataController: mockExposureDataController,
                                             pauseController: mockPauseController,
                                             pushNotificationStream: mockPushNotificationStream)
    }

    // MARK: - Tests

    func testSnapshotSettingsOverviewViewController_unpaused() {
        snapshots(matching: sut)
    }

    func testSnapshotSettingsOverviewViewController_paused() {
        mockExposureDataController.pauseEndDate = Date(timeIntervalSince1970: 1611408705)
        snapshots(matching: sut)
    }
}

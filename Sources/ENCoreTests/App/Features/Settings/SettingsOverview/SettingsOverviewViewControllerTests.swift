/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class SettingsOverviewViewControllerTests: TestCase {
    private var sut: SettingsOverviewViewController!
    private var mockListener: SettingsOverviewListenerMock!
    private var mockPauseController: PauseControllingMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockPushNotificationStream: PushNotificationStreamingMock!
    private var mockStorageController: StorageControllingMock!

    private let pushNotificationSubject = BehaviorSubject<UNNotification?>(value: nil)

    override func setUp() {
        super.setUp()

        recordSnapshots = false || forceRecordAllSnapshots

        mockListener = SettingsOverviewListenerMock()
        mockExposureDataController = ExposureDataControllingMock()
        mockPauseController = PauseControllingMock()
        mockPushNotificationStream = PushNotificationStreamingMock()
        mockStorageController = StorageControllingMock()

        mockPushNotificationStream.foregroundNotificationStream = pushNotificationSubject
            .subscribe(on: MainScheduler.instance)
            .distinctUntilChanged()
            .compactMap { $0 }

        mockExposureDataController.pauseEndDateObservable = .just(nil)

        mockPauseController.getPauseCountdownStringHandler = { _, _ in
            return NSAttributedString(string: "Some mock countdown string")
        }

        sut = SettingsOverviewViewController(listener: mockListener,
                                             theme: theme,
                                             exposureDataController: mockExposureDataController,
                                             pauseController: mockPauseController,
                                             pushNotificationStream: mockPushNotificationStream,
                                             storageController: mockStorageController)
    }

    // MARK: - Tests

    func testSnapshotSettingsOverviewViewController_unpaused() {
        snapshots(matching: sut)
    }

    func testSnapshotSettingsOverviewViewController_paused() {
        mockExposureDataController.pauseEndDate = Date(timeIntervalSince1970: 1611408705)
        snapshots(matching: sut)
    }

    func testSnapshotSettingsOverviewViewController_CoronadashboardEnabled() {
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(true)
        }
        snapshots(matching: sut)
    }

    func testSnapshotSettingsOverviewViewController_CoronadashboardDisabled() {
        mockStorageController.retrieveDataHandler = { _ in
            let jsonEncoder = JSONEncoder()
            return try! jsonEncoder.encode(false)
        }
        snapshots(matching: sut)
    }
}

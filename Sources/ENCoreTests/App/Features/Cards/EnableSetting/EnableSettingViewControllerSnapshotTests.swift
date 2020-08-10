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

final class EnableSettingViewControllerSnapshotTests: TestCase {
    private var viewController: EnableSettingViewController!
    private var bluetoothStateStream = BluetoothStateStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false
    }

    func test_enableBluetooth() {
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .enableBluetooth,
                                                     bluetoothStateStream: bluetoothStateStream)

        snapshots(matching: viewController)
    }

    func test_enableExposureNotifications() {
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .enableExposureNotifications,
                                                     bluetoothStateStream: bluetoothStateStream)

        snapshots(matching: viewController)
    }

    func test_enableLocalNotifications() {
        viewController = EnableSettingViewController(listener: EnableSettingListenerMock(),
                                                     theme: theme,
                                                     setting: .enableLocalNotifications,
                                                     bluetoothStateStream: bluetoothStateStream)

        snapshots(matching: viewController)
    }
}

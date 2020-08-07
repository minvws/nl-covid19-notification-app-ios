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

final class BluetoothSettingsViewControllerTests: TestCase {
    private var viewController: BluetoothSettingsViewController!
    private let listener = BluetoothSettingsListenerMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        viewController = BluetoothSettingsViewController(
            listener: listener,
            theme: theme)
    }

    // MARK: - Tests

    func test_snapshot_bluetoothSettingsViewControllerTests() {
        snapshots(matching: viewController)
    }
}

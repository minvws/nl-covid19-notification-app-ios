/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import EN
import ENFoundation
import Foundation
import SnapshotTesting
import XCTest

final class RequiresUpdateViewControllerTest: XCTestCase {

    private let theme = ENTheme()

    override func setUp() {
        super.setUp()

        record = false
        SnapshotTesting.diffTool = "ksdiff"
    }

    // MARK: - Tests

    func testSnapshotRequiresUpdateViewControllerWithUnsupportedDevice() {
        let updateHardwareViewController = RequiresUpdateViewController(deviceModel: "iPhone6,2", theme: theme)
        assertSnapshot(matching: updateHardwareViewController, as: .image())
    }

    func testSnapshotRequiresUpdateViewControllerWithSupportedDevice() {
        let updateSoftwareViewController = RequiresUpdateViewController(deviceModel: "iPhone8,2", theme: theme)
        assertSnapshot(matching: updateSoftwareViewController, as: .image())
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import SnapshotTesting
import XCTest

final class LaunchScreenViewControllerTests: TestCase {

    private var viewController: LaunchScreenViewController!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false || forceRecordAllSnapshots

        viewController = LaunchScreenViewController(theme: theme)
    }

    // MARK: - Tests

    func test_snapshot_launchScreenViewController() {
        snapshots(matching: viewController)
    }
}

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

final class AboutOverviewViewControllerTests: TestCase {

    private let listener = AboutOverviewListenerMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false || forceRecordAllSnapshots
    }

    // MARK: - Tests

    func test_snapshot_aboutOverviewViewController_renderCorrectly() {
        let aboutManager = AboutManager()
        let viewController = AboutOverviewViewController(listener: listener,
                                                         aboutManager: aboutManager,
                                                         theme: theme)
//        assertSnapshot(matching: snapshotWrapper(viewController.view, width: 320, height: 480), as: .recursiveDescription)
    }
}

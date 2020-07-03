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

final class HelpOverviewViewControllerTests: TestCase {

    private let listern = HelpOverviewListenerMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false
    }

    // MARK: - Tests

    func test_snapshot_helpOverviewViewController_shouldShowEnableAppButton() {
        assertSnapshot(matching: viewController(shouldShowEnableAppButton: true), as: .image())
    }

    func test_snapshot_helpOverviewViewController_hideShowEnableAppButton() {
        assertSnapshot(matching: viewController(shouldShowEnableAppButton: false), as: .image())
    }

    // MARK: - Private

    private func viewController(shouldShowEnableAppButton: Bool) -> HelpOverviewViewController {
        HelpOverviewViewController(listener: listern,
                                   shouldShowEnableAppButton: shouldShowEnableAppButton,
                                   helpManager: HelpManager(theme: theme),
                                   theme: theme)
    }
}

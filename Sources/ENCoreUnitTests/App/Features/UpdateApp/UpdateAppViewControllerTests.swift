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

final class UpdateAppViewControllerTests: XCTestCase {
    private var viewController: UpdateAppViewController!
    private let listern = UpdateAppListenerMock()

    override func setUp() {
        super.setUp()

        let theme = ENTheme()

        viewController = UpdateAppViewController(listener: listern, theme: theme)
    }

    // MARK: - Tests

    func testSnapshotUpdateAppViewController() {
        assertSnapshot(matching: viewController, as: .image())
    }
}

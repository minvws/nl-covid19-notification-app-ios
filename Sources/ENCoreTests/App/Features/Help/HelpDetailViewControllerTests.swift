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

final class HelpDetailViewControllerTests: TestCase {

    private var helpManager: HelpManager!
    private let listern = HelpDetailListenerMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false
        helpManager = HelpManager(theme: theme)
    }

    // MARK: - Tests

    func test_snapshot_helpDetailViewController() {
        for (index, question) in helpManager.questions.enumerated() {
            let viewController = HelpDetailViewController(listener: listern, shouldShowEnableAppButton: false, question: question, theme: theme)
            assertSnapshot(matching: viewController, as: .image(), named: "\(#function)\(index)")
        }
    }
}

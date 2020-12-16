/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import SnapshotTesting
import XCTest

final class HelpDetailViewControllerTests: TestCase {

    private var helpManager: HelpManager!
    private let listener = HelpDetailListenerMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        WebViewTestingOverrides.webViewLoadingEnabled = false

        helpManager = HelpManager()
    }

    // MARK: - Tests

    func test_snapshot_helpDetailViewController() {
        let detailEntries = helpManager.entries.filter {
            if case .question = $0 {
                return true
            } else {
                return false
            }
        }

        for (index, entry) in detailEntries.enumerated() {
            let viewController = HelpDetailViewController(listener: listener, shouldShowEnableAppButton: false, entry: entry, theme: theme)
            snapshots(matching: viewController, named: "\(#function)\(index)")
        }
    }

    func test_snapshot_helpDetailViewController_aboutManager() {
        let aboutManager = AboutManager()
        let detailEntries = aboutManager.questionsSection.entries.filter {
            if case .question = $0 {
                return true
            } else {
                return false
            }
        }

        for (index, entry) in detailEntries.enumerated() {
            let viewController = HelpDetailViewController(listener: listener, shouldShowEnableAppButton: false, entry: entry, theme: theme)
            snapshots(matching: viewController, named: "\(#function)\(index)")
        }
    }
}

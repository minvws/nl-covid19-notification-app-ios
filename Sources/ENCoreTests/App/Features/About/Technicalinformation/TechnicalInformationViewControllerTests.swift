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

final class TechnicalInformationViewControllerTests: TestCase {

    private let listener = TechnicalInformationListenerMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false || forceRecordAllSnapshots
    }

    // MARK: - Tests

    func test_snapshot_technicalInformationViewController_rendersCorrectly() {
        let viewController = TechnicalInformationViewController(listener: listener, linkedContent: [], theme: theme)
        snapshots(matching: viewController, as: .image())
    }
}

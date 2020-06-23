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

final class ThankYouViewControllerTests: XCTestCase {
    private var viewController: ThankYouViewController!
    private let listenr = ThankYouListenerMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        SnapshotTesting.diffTool = "ksdiff"
        SnapshotTesting.record = false

        let theme = ENTheme()

        let key = LabConfirmationKey(identifier: "Key Here",
                                     bucketIdentifier: Data(),
                                     confirmationKey: Data(),
                                     validUntil: Date())

        viewController = ThankYouViewController(listener: listenr,
                                                theme: theme,
                                                exposureConfirmationKey: key)
    }

    // MARK: - Tests

    func test_thankYou_snapshotStateLoading() {
        assertSnapshot(matching: viewController, as: .image())
    }
}

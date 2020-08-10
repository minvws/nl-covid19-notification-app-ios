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

final class PrivacyAgreementViewControllerTests: TestCase {

    private var viewController: PrivacyAgreementViewController!
    private let listener = PrivacyAgreementListenerMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false
        viewController = PrivacyAgreementViewController(listener: listener, theme: theme)
    }

    // MARK: - Tests

    func test_snapshot_privacyAgreementViewController() {
        snapshots(matching: viewController)
    }

    func test_snapshot_privacyAgreementViewController_accepted() {
        viewController.didPressAgreeWithPrivacyAgreementButton()
        snapshots(matching: viewController)
    }
}

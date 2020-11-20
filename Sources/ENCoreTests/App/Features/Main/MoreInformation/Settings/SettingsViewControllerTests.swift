/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import SnapshotTesting
import XCTest

final class SettingsViewControllerTests: TestCase {
    private var viewController: SettingsViewController!
    private let listener = SettingsListenerMock()
    private var interfaceOrientationStream = InterfaceOrientationStreamingMock()

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        interfaceOrientationStream.isLandscape = Just(false).eraseToAnyPublisher()

        viewController = SettingsViewController(listener: listener,
                                                theme: theme,
                                                interfaceOrientationStream: interfaceOrientationStream)
    }

    // MARK: - Tests

    func testSnapshotRequestTestViewController() {
        snapshots(matching: viewController)
    }

    func testPresentationControllerDidDismissCallsListener() {
        listener.settingstWantsDismissalHandler = { value in
            XCTAssertFalse(value)
        }

        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        XCTAssertEqual(listener.settingstWantsDismissalCallCount, 1)
    }
}

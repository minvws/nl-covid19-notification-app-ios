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

final class CardViewControllerSnapshotTests: TestCase {
    private var viewController: CardViewController!

    override func setUp() {
        super.setUp()

        recordSnapshots = false
    }

    func test_cardViewController_bluetoothOff() {
        viewController = CardViewController(theme: theme, type: .bluetoothOff)

        assertSnapshot(matching: viewController.view, as: .image())
    }

    func test_cardViewController_exposureOff() {
        viewController = CardViewController(theme: theme, type: .exposureOff)

        assertSnapshot(matching: viewController.view, as: .image())
    }

    func test_cardViewController_noLocalNotifications() {
        viewController = CardViewController(theme: theme, type: .noLocalNotifications)

        assertSnapshot(matching: viewController.view, as: .image())
    }

    func test_cardViewController_noInternet() {
        viewController = CardViewController(theme: theme, type: .noInternet(retryHandler: {}))

        assertSnapshot(matching: viewController.view, as: .image())
    }
}

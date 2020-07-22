/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class CardViewControllerTests: TestCase {
    private var viewController: CardViewController!
    private let router = CardRoutingMock()

    override func setUp() {
        super.setUp()

        viewController = CardViewController(theme: theme, type: .bluetoothOff)
        viewController.router = router
    }

    func test_enableSettingRequestsDismiss_forwardsToRouter() {
        var hideViewController: Bool!
        router.detachEnableSettingHandler = { hideViewController = $0 }

        XCTAssertEqual(router.detachEnableSettingCallCount, 0)

        viewController.enableSettingRequestsDismiss(shouldDismissViewController: false)

        XCTAssertEqual(router.detachEnableSettingCallCount, 1)
        XCTAssertFalse(hideViewController)
    }

    func test_enableSettingDidTriggerAction_forwardsToRouter() {
        var hideViewController: Bool!
        router.detachEnableSettingHandler = { hideViewController = $0 }

        XCTAssertEqual(router.detachEnableSettingCallCount, 0)

        viewController.enableSettingDidTriggerAction()

        XCTAssertEqual(router.detachEnableSettingCallCount, 1)
        XCTAssertTrue(hideViewController)
    }
}

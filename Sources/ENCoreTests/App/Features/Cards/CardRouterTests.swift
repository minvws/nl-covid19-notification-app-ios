/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class CardRouterTests: TestCase {
    private var router: CardRouter!
    private let viewController = CardViewControllableMock()
    private let enableSettingBuilder = EnableSettingBuildableMock()

    override func setUp() {
        super.setUp()

        router = CardRouter(viewController: viewController,
                            enableSettingBuilder: enableSettingBuilder)
    }

    func test_routeToEnableSetting_buildsAndPresents() {
        var receivedListener: EnableSettingListener!
        var receivedSetting: EnableSetting!
        enableSettingBuilder.buildHandler = { listener, setting in
            receivedListener = listener
            receivedSetting = setting

            return ViewControllableMock()
        }

        XCTAssertEqual(enableSettingBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)

        router.route(to: .enableBluetooth)

        XCTAssertEqual(enableSettingBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
        XCTAssert(receivedListener === viewController)
        XCTAssertEqual(receivedSetting, .enableBluetooth)
    }

    func test_detachEnableSetting_hideViewController_callsViewController() {
        router.route(to: .enableBluetooth)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachEnableSetting(hideViewController: true)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_detachEnableSetting_dontHideViewController_doesNotCallViewController() {
        router.route(to: .enableBluetooth)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachEnableSetting(hideViewController: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)
    }

    func test_detachEnableSetting_hideViewController_notPresentedBefore_doesNotCallViewController() {
        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachEnableSetting(hideViewController: true)

        XCTAssertEqual(viewController.dismissCallCount, 0)
    }

    func test_setCardType_forwardToViewController() {
        var receivedCardTypes: [CardType]!
        viewController.updateHandler = { receivedCardTypes = $0 }

        XCTAssertEqual(viewController.updateCallCount, 0)

        router.type = .bluetoothOff

        XCTAssertEqual(viewController.updateCallCount, 1)

        guard case .bluetoothOff = receivedCardTypes.first else {
            XCTFail("Expected bluetoothOff cardType")
            return
        }
    }
}

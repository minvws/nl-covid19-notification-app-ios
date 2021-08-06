/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation

import Foundation
import XCTest

final class CardViewControllerTests: TestCase {
    private var viewController: CardViewController!
    private let mockRouter = CardRoutingMock()
    private var mockCardListener: CardListeningMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockPauseController: PauseControllingMock!

    override func setUp() {
        super.setUp()

        recordSnapshots = false || forceRecordAllSnapshots
        mockCardListener = CardListeningMock()
        mockExposureDataController = ExposureDataControllingMock()
        mockPauseController = PauseControllingMock()

        viewController = CardViewController(listener: mockCardListener,
                                            theme: theme,
                                            types: [.bluetoothOff],
                                            dataController: mockExposureDataController,
                                            pauseController: mockPauseController)
        viewController.router = mockRouter
    }

    func test_enableSettingRequestsDismiss_forwardsToRouter() {
        var hideViewController: Bool!
        mockRouter.detachEnableSettingHandler = { hideViewController = $0 }

        XCTAssertEqual(mockRouter.detachEnableSettingCallCount, 0)

        viewController.enableSettingRequestsDismiss(shouldDismissViewController: false)

        XCTAssertEqual(mockRouter.detachEnableSettingCallCount, 1)
        XCTAssertFalse(hideViewController)
    }

    func test_enableSettingDidTriggerAction_forwardsToRouter() {
        var hideViewController: Bool!
        mockRouter.detachEnableSettingHandler = { hideViewController = $0 }

        XCTAssertEqual(mockRouter.detachEnableSettingCallCount, 0)

        viewController.enableSettingDidTriggerAction()

        XCTAssertEqual(mockRouter.detachEnableSettingCallCount, 1)
        XCTAssertTrue(hideViewController)
    }
}

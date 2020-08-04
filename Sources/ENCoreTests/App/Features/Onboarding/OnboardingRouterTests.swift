/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class OnboardingRouterTests: XCTestCase {
    private let viewController = OnboardingViewControllableMock()
    private let stepBuilder = OnboardingStepBuildableMock()
    private let consentBuilder = OnboardingConsentBuildableMock()
    private let helpBuilder = HelpBuildableMock()
    private let bluetoothSettingsBuilder = BluetoothSettingsBuildableMock()
    private let shareSheetBuilder = ShareSheetBuildableMock()

    private var router: OnboardingRouter!

    override func setUp() {
        super.setUp()

        // TODO: Add other dependencies
        router = OnboardingRouter(viewController: viewController,
                                  stepBuilder: stepBuilder,
                                  consentBuilder: consentBuilder,
                                  bluetoothSettingsBuilder: bluetoothSettingsBuilder,
                                  shareSheetBuilder: shareSheetBuilder,
                                  helpBuilder: helpBuilder)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    // TODO: Add more tests
}

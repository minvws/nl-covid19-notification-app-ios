/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class OnboardingRouterTests: TestCase {
    private let viewController = OnboardingViewControllableMock()
    private let stepBuilder = OnboardingStepBuildableMock()
    private let consentBuilder = OnboardingConsentBuildableMock()
    private let helpBuilder = HelpBuildableMock()
    private let bluetoothSettingsBuilder = BluetoothSettingsBuildableMock()
    private let privacyAgreementBuilder = PrivacyAgreementBuildableMock()
    private let shareSheetBuilder = ShareSheetBuildableMock()
    private let webviewBuilder = WebviewBuildableMock()

    private var router: OnboardingRouter!

    override func setUp() {
        super.setUp()

        router = OnboardingRouter(viewController: viewController,
                                  stepBuilder: stepBuilder,
                                  consentBuilder: consentBuilder,
                                  bluetoothSettingsBuilder: bluetoothSettingsBuilder,
                                  shareSheetBuilder: shareSheetBuilder,
                                  privacyAgreementBuilder: privacyAgreementBuilder,
                                  helpBuilder: helpBuilder,
                                  webviewBuilder: webviewBuilder)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    func test_routeToHelp_andDismissal() {

        router.routeToHelp()

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToConsent_andDismissal() {

        router.routeToConsent(animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToSteps_andDismissal() {

        router.routeToSteps()

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToPrivacyAgreement_andDismissal() {

        router.routeToPrivacyAgreement()

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToBluetoothSettings_andDismissal() {

        router.routeToBluetoothSettings()

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingHelpStopTheSpreadofCoronavirusStep_andDismissal() {

        router.routeToStep(withIndex: 0, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingNotificationInformation_andDismissal() {

        router.routeToStep(withIndex: 1, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingBluetoothIformation_andDismissal() {

        router.routeToStep(withIndex: 2, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingNoNotificationIformation_andDismissal() {

        router.routeToStep(withIndex: 3, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingWillGetNotificationIformation_andDismissal() {

        router.routeToStep(withIndex: 4, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToEnConsentStep_andDismissal() {

        router.routeToConsent(withIndex: 0, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToBluetoothConsentStep_andDismissal() {

        router.routeToConsent(withIndex: 1, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToShareConsentStep_andDismissal() {

        router.routeToConsent(withIndex: 2, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }
}

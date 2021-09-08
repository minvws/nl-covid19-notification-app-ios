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
    private var mockEnableSettingsBuilder = EnableSettingBuildableMock()

    private var mockPrivacyAgreementViewControllable: ViewControllableMock!
    private var mockConsentViewControllable: ViewControllableMock!

    private var sut: OnboardingRouter!

    override func setUp() {
        super.setUp()

        mockPrivacyAgreementViewControllable = ViewControllableMock()
        mockConsentViewControllable = ViewControllableMock()

        privacyAgreementBuilder.buildHandler = { _ in self.mockPrivacyAgreementViewControllable }
        consentBuilder.buildHandler = { _ in self.mockConsentViewControllable }

        sut = OnboardingRouter(viewController: viewController,
                               stepBuilder: stepBuilder,
                               consentBuilder: consentBuilder,
                               bluetoothSettingsBuilder: bluetoothSettingsBuilder,
                               shareSheetBuilder: shareSheetBuilder,
                               privacyAgreementBuilder: privacyAgreementBuilder,
                               helpBuilder: helpBuilder,
                               webviewBuilder: webviewBuilder,
                               enableSettingBuilder: mockEnableSettingsBuilder)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    func test_routeToSteps() {
        let mockViewController = ViewControllableMock()
        stepBuilder.buildHandler = { _ in mockViewController }

        XCTAssertEqual(viewController.pushCallCount, 0)
        XCTAssertEqual(stepBuilder.buildCallCount, 0)

        sut.routeToSteps()

        XCTAssertEqual(stepBuilder.buildCallCount, 1)
        XCTAssertTrue(stepBuilder.buildArgValues.first === viewController)

        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertTrue(viewController.pushArgValues.first!.0 === mockViewController)
        XCTAssertFalse(viewController.pushArgValues.first!.1)
    }

    func test_routeToSteps_shouldNotRouteMultipleTimes() {
        let mockViewController = ViewControllableMock()
        stepBuilder.buildHandler = { _ in mockViewController }

        XCTAssertEqual(viewController.pushCallCount, 0)
        XCTAssertEqual(stepBuilder.buildCallCount, 0)

        sut.routeToSteps()
        sut.routeToSteps()

        XCTAssertEqual(stepBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.pushCallCount, 1)
    }

    func test_routeToStep() {
        let mockViewController = ViewControllableMock()
        stepBuilder.buildWithListenerHandler = { _, _ in mockViewController }

        let stepIndex = 2

        XCTAssertEqual(viewController.pushCallCount, 0)
        XCTAssertEqual(stepBuilder.buildWithListenerCallCount, 0)

        sut.routeToStep(withIndex: stepIndex)

        XCTAssertEqual(stepBuilder.buildWithListenerCallCount, 1)
        XCTAssertTrue(stepBuilder.buildWithListenerArgValues.first?.0 === viewController)
        XCTAssertEqual(stepBuilder.buildWithListenerArgValues.first?.1, stepIndex)

        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertTrue(viewController.pushArgValues.first!.0 === mockViewController)
        XCTAssertTrue(viewController.pushArgValues.first!.1)
    }

    func test_routeToConsent() {
        // Arrange
        XCTAssertEqual(viewController.pushCallCount, 0)

        // Act
        sut.routeToConsent()

        // Assert
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertTrue(viewController.pushArgValues.first!.0 === mockConsentViewControllable)
        XCTAssertTrue(viewController.pushArgValues.first!.1)
    }

    func test_routeToEnConsentStep_andDismissal() {

        sut.routeToConsent(withIndex: 0, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToPrivacyAgreement() {

        // Arrange
        XCTAssertEqual(viewController.pushCallCount, 0)

        // Act
        sut.routeToPrivacyAgreement()

        // Assert
        XCTAssertEqual(viewController.pushCallCount, 1)
        XCTAssertTrue(viewController.pushArgValues.first!.0 === mockPrivacyAgreementViewControllable)
        XCTAssertTrue(viewController.pushArgValues.first!.1)
    }

    func test_routeToWebview() {
        // Arrange
        let mockWebView = ViewControllableMock()
        let url = URL(string: "http://www.someurl.com")!
        webviewBuilder.buildHandler = { _, _ in mockWebView }

        XCTAssertEqual(webviewBuilder.buildCallCount, 0)

        // Act
        sut.routeToWebview(url: url)

        // Assert
        XCTAssertEqual(webviewBuilder.buildCallCount, 1)
        XCTAssertEqual(webviewBuilder.buildArgValues.first!.1, url)
        XCTAssertTrue(viewController.presentInNavigationControllerArgValues.first!.0 === mockWebView)
        XCTAssertTrue(viewController.presentInNavigationControllerArgValues.first!.1)
    }

    func test_dismissWebview() {
        // Arrange
        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.routeToWebview(url: URL(string: "http://www.someurl.com")!)

        // Act
        sut.dismissWebview(shouldHideViewController: true)

        // Assert
        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToHelp() {
        // Arrange
        let mockRouting = RoutingMock()
        let mockViewControllable = ViewControllableMock()
        mockRouting.viewControllable = mockViewControllable
        helpBuilder.buildHandler = { _, _ in mockRouting }

        XCTAssertEqual(viewController.pushCallCount, 0)
        XCTAssertEqual(helpBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)

        // Act
        sut.routeToHelp()

        // Assert
        XCTAssertEqual(helpBuilder.buildCallCount, 1)
        XCTAssertTrue(helpBuilder.buildArgValues.first!.0 === viewController)
        XCTAssertTrue(helpBuilder.buildArgValues.first!.1)
        XCTAssertEqual(viewController.presentCallCount, 1)
        XCTAssertTrue(viewController.presentArgValues.first!.0 === mockViewControllable)
        XCTAssertTrue(viewController.presentArgValues.first!.1)
    }

    func test_routeToBluetoothSettings() {
        // Arrange
        let mockViewControllable = ViewControllableMock()
        bluetoothSettingsBuilder.buildHandler = { _ in mockViewControllable }

        XCTAssertEqual(viewController.pushCallCount, 0)
        XCTAssertEqual(bluetoothSettingsBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)

        // Act
        sut.routeToBluetoothSettings()

        // Assert
        XCTAssertEqual(bluetoothSettingsBuilder.buildCallCount, 1)
        XCTAssertTrue(bluetoothSettingsBuilder.buildArgValues.first! === viewController)
        XCTAssertEqual(viewController.presentCallCount, 1)
        XCTAssertTrue(viewController.presentArgValues.first!.0 === mockViewControllable)
        XCTAssertTrue(viewController.presentArgValues.first!.1)
    }

    func test_routeToShareApp() throws {
        // Arrange
        XCTAssertEqual(viewController.presentActivityViewControllerCallCount, 0)

        // Act
        sut.routeToShareApp()

        // Assert
        XCTAssertEqual(viewController.presentActivityViewControllerCallCount, 1)
    }

    func test_routeToOnboardingHelpStopTheSpreadofCoronavirusStep_andDismissal() {

        sut.routeToStep(withIndex: 0)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingNotificationInformation_andDismissal() {

        sut.routeToStep(withIndex: 1)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingBluetoothIformation_andDismissal() {

        sut.routeToStep(withIndex: 2)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingNoNotificationIformation_andDismissal() {

        sut.routeToStep(withIndex: 3)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToOnboardingWillGetNotificationIformation_andDismissal() {

        sut.routeToStep(withIndex: 4)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToBluetoothConsentStep_andDismissal() {

        sut.routeToConsent(withIndex: 1, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToShareConsentStep_andDismissal() {

        sut.routeToConsent(withIndex: 2, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        sut.viewController.dismiss(viewController: viewController, animated: false)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_routeToExposureNotificationSettings() {

        var receivedListener: EnableSettingListener!
        var receivedSetting: EnableSetting!
        mockEnableSettingsBuilder.buildHandler = { listener, setting in
            receivedListener = listener
            receivedSetting = setting

            return ViewControllableMock()
        }

        XCTAssertEqual(mockEnableSettingsBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.uiviewControllerSetCallCount, 0)

        sut.routeToExposureNotificationSettings()

        XCTAssert(receivedListener === viewController)
        XCTAssertEqual(receivedSetting, .enableExposureNotifications)
        XCTAssertEqual(mockEnableSettingsBuilder.buildCallCount, 1)
    }
}

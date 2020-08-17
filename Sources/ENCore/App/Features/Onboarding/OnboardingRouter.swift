/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol OnboardingViewControllable: ViewControllable, OnboardingStepListener, OnboardingConsentListener, HelpListener, BluetoothSettingsListener, PrivacyAgreementListener, WebviewListener {
    var router: OnboardingRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    func presentInNavigationController(viewController: ViewControllable, animated: Bool)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class OnboardingRouter: Router<OnboardingViewControllable>, OnboardingRouting {

    init(viewController: OnboardingViewControllable,
         stepBuilder: OnboardingStepBuildable,
         consentBuilder: OnboardingConsentBuildable,
         bluetoothSettingsBuilder: BluetoothSettingsBuildable,
         shareSheetBuilder: ShareSheetBuildable,
         privacyAgreementBuilder: PrivacyAgreementBuildable,
         helpBuilder: HelpBuildable,
         webviewBuilder: WebviewBuildable) {
        self.stepBuilder = stepBuilder
        self.consentBuilder = consentBuilder
        self.bluetoothSettingsBuilder = bluetoothSettingsBuilder
        self.shareSheetBuilder = shareSheetBuilder
        self.privacyAgreementBuilder = privacyAgreementBuilder
        self.helpBuilder = helpBuilder
        self.webviewBuilder = webviewBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }

    func routeToSteps() {
        guard stepViewController == nil else {
            return
        }

        let stepViewController = stepBuilder.build(withListener: viewController)
        self.stepViewController = stepViewController

        viewController.push(viewController: stepViewController, animated: false)
    }

    func routeToStep(withIndex index: Int, animated: Bool) {

        let stepViewController = stepBuilder.build(withListener: viewController, initialIndex: index)
        self.stepViewController = stepViewController

        viewController.push(viewController: stepViewController, animated: animated)
    }

    func routeToConsent(animated: Bool) {
        let consentViewController = consentBuilder.build(withListener: viewController)
        self.consentViewController = consentViewController

        viewController.push(viewController: consentViewController, animated: animated)
    }

    func routeToConsent(withIndex index: Int, animated: Bool) {
        let consentViewController = consentBuilder.build(withListener: viewController, initialIndex: index)
        self.consentViewController = consentViewController

        viewController.push(viewController: consentViewController, animated: animated)
    }

    func routeToPrivacyAgreement() {
        let privacyAgreementViewController = privacyAgreementBuilder.build(withListener: viewController)
        self.privacyAgreementViewController = privacyAgreementViewController
        viewController.push(viewController: privacyAgreementViewController, animated: true)
    }

    func routeToWebview(url: URL) {
        let webviewViewController = webviewBuilder.build(withListener: viewController, url: url)
        self.webviewViewController = webviewViewController
        viewController.presentInNavigationController(viewController: webviewViewController, animated: true)
    }

    func dismissWebview(shouldHideViewController: Bool) {
        guard let webviewViewController = webviewViewController else { return }

        self.webviewViewController = nil

        if shouldHideViewController {
            viewController.dismiss(viewController: webviewViewController, animated: true)
        }
    }

    func routeToHelp() {
        let helpRouter = helpBuilder.build(withListener: viewController, shouldShowEnableAppButton: true)
        self.helpRouter = helpRouter

        viewController.present(viewController: helpRouter.viewControllable,
                               animated: true,
                               completion: nil)
    }

    func routeToBluetoothSettings() {
        let bluetoothSettingsViewController = bluetoothSettingsBuilder.build(withListener: viewController)
        self.bluetoothSettingsViewController = bluetoothSettingsViewController

        viewController.present(viewController: bluetoothSettingsViewController,
                               animated: true,
                               completion: nil)
    }

    private let stepBuilder: OnboardingStepBuildable
    private var stepViewController: ViewControllable?

    private let consentBuilder: OnboardingConsentBuildable
    private var consentViewController: ViewControllable?

    private let shareSheetBuilder: ShareSheetBuildable
    private var shareSheetViewController: ShareSheetViewControllable?

    private let privacyAgreementBuilder: PrivacyAgreementBuildable
    private var privacyAgreementViewController: ViewControllable?

    private let bluetoothSettingsBuilder: BluetoothSettingsBuildable
    private var bluetoothSettingsViewController: ViewControllable?

    private let helpBuilder: HelpBuildable
    private var helpViewController: ViewControllable?
    private var helpRouter: Routing?

    private let webviewBuilder: WebviewBuildable
    private var webviewViewController: ViewControllable?
}

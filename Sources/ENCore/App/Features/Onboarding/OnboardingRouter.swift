/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

/// @mockable(history:push=true;present=true;presentInNavigationController=true)
protocol OnboardingViewControllable: ViewControllable, OnboardingStepListener, OnboardingConsentListener, HelpListener, BluetoothSettingsListener, PrivacyAgreementListener, WebviewListener, EnableSettingListener {
    var router: OnboardingRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    func present(activityViewController: UIActivityViewController, animated: Bool, completion: (() -> ())?)
    func presentInNavigationController(viewController: ViewControllable, animated: Bool)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class OnboardingRouter: Router<OnboardingViewControllable>, OnboardingRouting, Logging {

    init(viewController: OnboardingViewControllable,
         stepBuilder: OnboardingStepBuildable,
         consentBuilder: OnboardingConsentBuildable,
         bluetoothSettingsBuilder: BluetoothSettingsBuildable,
         shareSheetBuilder: ShareSheetBuildable,
         privacyAgreementBuilder: PrivacyAgreementBuildable,
         helpBuilder: HelpBuildable,
         webviewBuilder: WebviewBuildable,
         enableSettingBuilder: EnableSettingBuildable) {
        self.stepBuilder = stepBuilder
        self.consentBuilder = consentBuilder
        self.bluetoothSettingsBuilder = bluetoothSettingsBuilder
        self.shareSheetBuilder = shareSheetBuilder
        self.privacyAgreementBuilder = privacyAgreementBuilder
        self.helpBuilder = helpBuilder
        self.webviewBuilder = webviewBuilder
        self.enableSettingBuilder = enableSettingBuilder

        // These viewcontrollers take some time to build. We build them before starting the onboarding flow to speed up the UI once the use hits these screens
        self.privacyAgreementViewController = privacyAgreementBuilder.build(withListener: viewController)
        self.consentViewController = consentBuilder.build(withListener: viewController)

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

    func routeToStep(withIndex index: Int) {
        let stepViewController = stepBuilder.build(withListener: viewController, initialIndex: index)
        self.stepViewController = stepViewController

        viewController.push(viewController: stepViewController, animated: true)
    }

    func routeToConsent() {
        viewController.push(viewController: consentViewController, animated: true)
    }

    func routeToConsent(withIndex index: Int, animated: Bool) {
        let consentViewController = consentBuilder.build(withListener: viewController, initialIndex: index)
        self.consentViewController = consentViewController

        viewController.push(viewController: consentViewController, animated: animated)
    }

    func routeToPrivacyAgreement() {
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

    func routeToShareApp() {
        if let storeLink = URL(string: .shareAppUrl) {
            let activityVC = UIActivityViewController(activityItems: [.shareAppTitle as String, storeLink], applicationActivities: nil)
            viewController.present(activityViewController: activityVC, animated: true, completion: nil)
        } else {
            self.logError("Couldn't retreive a valid url")
        }
    }

    func routeToExposureNotificationSettings() {
        guard enableSettingViewController == nil else {
            return
        }

        let enableSettingViewController = enableSettingBuilder.build(withListener: viewController, setting: .enableExposureNotifications)
        self.enableSettingViewController = enableSettingViewController

        viewController.present(viewController: enableSettingViewController,
                               animated: true,
                               completion: nil)
    }

    func dismissExposureNotificationSettings(_ shouldDismissViewController: Bool) {
        guard let enableSettingViewController = enableSettingViewController else { return }

        self.enableSettingViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: enableSettingViewController, animated: true)
        }
    }

    private let stepBuilder: OnboardingStepBuildable
    private var stepViewController: ViewControllable?

    private let consentBuilder: OnboardingConsentBuildable
    private var consentViewController: ViewControllable

    private let shareSheetBuilder: ShareSheetBuildable
    private var shareSheetViewController: ShareSheetViewControllable?

    private let privacyAgreementBuilder: PrivacyAgreementBuildable
    private var privacyAgreementViewController: ViewControllable

    private let bluetoothSettingsBuilder: BluetoothSettingsBuildable
    private var bluetoothSettingsViewController: ViewControllable?

    private let helpBuilder: HelpBuildable
    private var helpViewController: ViewControllable?
    private var helpRouter: Routing?

    private let webviewBuilder: WebviewBuildable
    private var webviewViewController: ViewControllable?

    private let enableSettingBuilder: EnableSettingBuildable
    private var enableSettingViewController: ViewControllable?
}

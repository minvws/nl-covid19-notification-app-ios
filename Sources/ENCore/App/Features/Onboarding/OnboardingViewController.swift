/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

/// @mockable
protocol OnboardingRouting: Routing {
    func routeToSteps()
    func routeToStep(withIndex index: Int, animated: Bool)
    func routeToConsent(animated: Bool)
    func routeToConsent(withIndex index: Int, animated: Bool)
    func routeToHelp()
    func routeToBluetoothSettings()
    func routeToPrivacyAgreement()
}

final class OnboardingViewController: NavigationController, OnboardingViewControllable, Logging {

    weak var router: OnboardingRouting?

    init(onboardingConsentManager: OnboardingConsentManaging,
        listener: OnboardingListener, theme: Theme) {
        self.onboardingConsentManager = onboardingConsentManager
        self.listener = listener
        super.init(theme: theme)
        modalPresentationStyle = .fullScreen
    }

    // MARK: - OnboardingViewControllable

    func push(viewController: ViewControllable, animated: Bool) {
        pushViewController(viewController.uiviewController, animated: animated)
    }

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController, animated: animated, completion: completion)
    }

    // MARK: - OnboardingStepListener

    func onboardingStepsDidComplete() {
        router?.routeToPrivacyAgreement()
    }

    func nextStepAtIndex(_ index: Int) {
        router?.routeToStep(withIndex: index, animated: true)
    }

    // MARK: - OnboardingConsentListener

    func consentClose() {
        listener?.didCompleteOnboarding()
    }

    func consentRequest(step: OnboardingConsentStepIndex) {
        router?.routeToConsent(withIndex: step.rawValue, animated: true)
    }

    // MARK: - PrivacyAgreementListener

    func privacyAgreementDidComplete() {
        router?.routeToConsent(animated: true)
    }

    // MARK: - HelpListener

    func displayHelp() {
        router?.routeToHelp()
    }

    func helpRequestsDismissal(shouldHideViewController: Bool) {
        // empty body
    }

    func displayBluetoothSettings() {
        router?.routeToBluetoothSettings()
    }

    func isBluetoothEnabled(_ completion: @escaping ((Bool) -> ())) {
        onboardingConsentManager.isBluetoothEnabled { enabled in
            completion(enabled)
        }
    }

    func bluetoothSettingsDidComplete() {
        dismiss(animated: true) {
            self.onboardingConsentManager.getNextConsentStep(.bluetooth, skippedCurrentStep: false) { nextStep in
                if let nextStep = nextStep {
                    self.router?.routeToConsent(withIndex: nextStep.rawValue, animated: true)
                } else {
                    self.listener?.didCompleteOnboarding()
                }
            }
        }
    }

    func helpRequestsEnableApp() {
        onboardingConsentManager.askEnableExposureNotifications { activeState in
            switch activeState {
            case .notAuthorized:
                self.listener?.didCompleteOnboarding()
            default:
                self.onboardingConsentManager.getNextConsentStep(.en, skippedCurrentStep: false) { nextStep in
                    if let nextStep = nextStep {
                        self.router?.routeToConsent(withIndex: nextStep.rawValue, animated: true)
                    } else {
                        self.listener?.didCompleteOnboarding()
                    }
                }
            }
        }
    }

    func displayShareApp(completion: (() -> ())?) {
        if let storeLink = URL(string: .shareAppUrl) {
            let activityVC = UIActivityViewController(activityItems: [.shareAppTitle as String, storeLink], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                if let handler = completion {
                    handler()
                }
            }
            self.present(activityVC, animated: true)
        } else {
            self.logError("Couldn't retreive a valid url")
        }
    }

    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        router?.routeToSteps()
    }

    // MARK: - Private

    private weak var listener: OnboardingListener?
    private let onboardingConsentManager: OnboardingConsentManaging
}

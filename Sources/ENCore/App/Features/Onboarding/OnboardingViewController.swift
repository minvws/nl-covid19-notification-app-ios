/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol OnboardingRouting: Routing {
    func routeToSteps()
    func routeToConsent(animated: Bool)
    func routeToConsent(withIndex index: Int, animated: Bool)
}

final class OnboardingViewController: NavigationController, OnboardingViewControllable {

    weak var router: OnboardingRouting?

    init(listener: OnboardingListener, theme: Theme) {
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

        router?.routeToConsent(animated: true)
    }

    // MARK: - OnboardingConsentListener

    func consentClose() {
        listener?.didCompleteOnboarding()
    }

    func consentRequest(step: OnboardingConsentStepIndex) {
        router?.routeToConsent(withIndex: step.rawValue, animated: true)
    }

    // MARK: - OnboardingHelpListener

    func displayHelp() {
        listener?.displayHelp()
    }

    func helpRequestsFAQ() { }

    func helpRequestsPermission() { }

    func helpRequestsClose() { }

    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        router?.routeToSteps()
    }

    // MARK: - Private

    private weak var listener: OnboardingListener?
}


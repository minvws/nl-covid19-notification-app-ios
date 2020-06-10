/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol OnboardingViewControllable: ViewControllable, OnboardingStepListener, OnboardingConsentListener {
    var router: OnboardingRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
}

final class OnboardingRouter: Router<OnboardingViewControllable>, OnboardingRouting {
    init(viewController: OnboardingViewControllable,
         stepBuilder: OnboardingStepBuildable,
         consentBuilder: OnboardingConsentBuildable,
         helpBuilder: OnboardingHelpBuildable,
         webBuilder: WebBuildable,
         shareSheetBuilder: ShareSheetBuildable) {
        self.stepBuilder = stepBuilder
        self.consentBuilder = consentBuilder
        self.helpBuilder = helpBuilder
        self.webBuilder = webBuilder
        self.shareSheetBuilder = shareSheetBuilder

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

    func routeToConsent(animated: Bool) {
        let consentViewController = consentBuilder.build(withListener: viewController)
        self.consentViewController = consentViewController

        viewController.push(viewController: consentViewController, animated: animated)
    }

    private let stepBuilder: OnboardingStepBuildable
    private var stepViewController: ViewControllable?

    private let consentBuilder: OnboardingConsentBuildable
    private var consentViewController: ViewControllable?

    private let helpBuilder: OnboardingHelpBuildable
    private var helpViewController: ViewControllable?

    private let webBuilder: WebBuildable
    private var webViewController: ViewControllable?

    private let shareSheetBuilder: ShareSheetBuildable
    private var shareSheetViewController: ShareSheetViewControllable?
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol OnboardingHelpViewControllable: ViewControllable, OnboardingHelpListener {
    var router: OnboardingHelpRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    
    func acceptButtonPressed()
}

final class OnboardingHelpRouter: Router<OnboardingHelpViewControllable>, OnboardingHelpRouting {

    init(viewController: OnboardingHelpViewControllable,
        helpBuilder: OnboardingHelpBuildable) {

        self.helpBuilder = helpBuilder
        
        super.init(viewController: viewController)

        viewController.router = self
    }
    
    func routeToHelp() {
        guard helpOverviewViewController == nil else {
            return
        }

        let helpOverviewViewController = helpBuilder.buildOverview(withListener: viewController)
        self.helpOverviewViewController = helpOverviewViewController

        viewController.push(viewController: helpOverviewViewController, animated: false)
    }

    func routeToHelpDetail(withOnboardingConsentHelp onboardingConsentHelp: OnboardingConsentHelp) {
        let helpDetailViewController = helpBuilder.buildDetail(withListener: viewController, onboardingConsentHelp: onboardingConsentHelp)
        self.helpDetailViewController = helpDetailViewController

        viewController.push(viewController: helpDetailViewController, animated: false)
    }

    private let helpBuilder: OnboardingHelpBuildable
    
    private var helpOverviewViewController: ViewControllable?
    private var helpDetailViewController: ViewControllable?
}

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
         onboardingStepBuilder: OnboardingStepBuildable,
         onboardingConsentBuilder: OnboardingConsentBuildable) {
        
        self.onboardingStepBuilder = onboardingStepBuilder
        self.onboardingConsentBuilder = onboardingConsentBuilder
        
        super.init(viewController: viewController)
        
        viewController.router = self
    }
    
    func routeToSteps() {
        guard onboardingStepViewController == nil else {
            return
        }
        
        let onboardingStepViewController = onboardingStepBuilder.build(withListener: viewController)
        self.onboardingStepViewController = onboardingStepViewController
        
        viewController.push(viewController: onboardingStepViewController, animated: false)
    }
    
    func routeToConsent() {
        
        let onboardingConsentViewController = onboardingConsentBuilder.build(withListener: viewController)
        self.onboardingConsentViewController = onboardingConsentViewController
        
        viewController.push(viewController: onboardingConsentViewController, animated: false)
    }
    
    private let onboardingStepBuilder: OnboardingStepBuildable
    private var onboardingStepViewController: ViewControllable?
    
    private let onboardingConsentBuilder: OnboardingConsentBuildable
    private var onboardingConsentViewController: ViewControllable?
}

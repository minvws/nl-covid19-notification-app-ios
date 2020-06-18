/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import WebKit

/// @mockable
protocol OnboardingHelpRouting: Routing {
    func routeToHelp()
    func routeToHelpDetail(withOnboardingConsentHelp onboardingConsentHelp: OnboardingConsentHelp)
}

final class OnboardingHelpViewController: NavigationController, OnboardingHelpViewControllable {
    
    weak var router: OnboardingHelpRouting?

    init(listener: OnboardingHelpListener, theme: Theme) {
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

    func acceptButtonPressed() {
        
    }
    
    func displayHelp() {
        
    }
    
    func displayHelpDetail(withOnboardingConsentHelp onboardingConsentHelp: OnboardingConsentHelp) {
        
    }

    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        router?.routeToHelp()
    }

    // MARK: - Private

    private weak var listener: OnboardingHelpListener?
}


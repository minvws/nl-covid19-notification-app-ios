/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// Routing interface for the Root feature. Contains functions that are
/// called from `RootViewController`.
/// 
/// @mockable
protocol RootRouting: Routing {
    /// Detaches the onboarding feature and calls completion when done.
    /// When the onboarding flow is not attached, completion is called immediately
    ///
    /// - Parameter animated: Animates the dismissal animation
    func detachOnboardingAndRouteToMain(animated: Bool)
}

final class RootViewController: ViewController, RootViewControllable {
    
    // MARK: - RootViewControllable
    
    weak var router: RootRouting?
    
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController,
                animated: animated,
                completion: completion)
    }
    
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        viewController.uiviewController.dismiss(animated: animated, completion: completion)
    }
    
    func embed(viewController: ViewControllable) {
        addChild(viewController.uiviewController)
        view.addSubview(viewController.uiviewController.view)
        viewController.uiviewController.didMove(toParent: self)
    }
    
    // MARK: - OnboardingListener
    
    func didCompleteOnboarding() {
        router?.detachOnboardingAndRouteToMain(animated: true)
    }

}

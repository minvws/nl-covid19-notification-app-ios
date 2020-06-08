/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// Routing interface for the Root feature. Contains functions that are
/// called from `RootViewController`.
protocol RootRouting: Routing {
    /// Detaches the onboarding feature and calls completion when done.
    /// When the onboarding flow is not attached, completion is called immediately
    ///
    /// - Parameter animated: Animates the dismissal animation
    /// - Parameter completion: Executed after completed detaching
    func detachOnboarding(animated: Bool, completion: @escaping () -> ())
    
    /// Routes to the main feature. When main is already attached this
    /// function does nothing.
    func routeToMain()
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
    
    // MARK: - OnboardingListener
    
    func didCompleteOnboarding() {
        router?.detachOnboarding(animated: true) {
            self.router?.routeToMain()
        }
    }

}

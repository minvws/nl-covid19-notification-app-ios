/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// Describes internal `RootViewController` functionality. Contains functions
/// that can be called from `RootRouter`. Should not be exposed
/// from `RootBuilder`. `RootBuilder` returns an `AppEntryPoint` instance instead
/// which is implemented by `RootRouter`.
///
/// @mockable
protocol RootViewControllable: ViewControllable, OnboardingListener {
    var router: RootRouting? { get set }

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
}

final class RootRouter: Router<RootViewControllable>, RootRouting, AppEntryPoint {
    
    // MARK: - Initialisation
    
    init(viewController: RootViewControllable,
         onboardingBuilder: OnboardingBuildable,
         mainBuilder: MainBuildable) {
        self.onboardingBuilder = onboardingBuilder
        self.mainBuilder = mainBuilder
        
        super.init(viewController: viewController)
        
        viewController.router = self
    }
    
    // MARK: - AppEntryPoint
    
    var uiviewController: UIViewController {
        return viewController.uiviewController
    }
    
    func start() {
        routeToOnboarding()
    }
    
    // MARK: - RootRouting
    
    func routeToMain() {
        guard mainViewController == nil else {
            // already presented
            return
        }
        
        let mainViewController = self.mainBuilder.build()
        self.mainViewController = mainViewController
        
        self.viewController.present(viewController: mainViewController,
                                    animated: true,
                                    completion: nil)
    }
    
    func detachOnboarding(animated: Bool, completion: @escaping () -> ()) {
        guard let onboardingRouter = onboardingRouter else {
            completion()
            return
        }
        
        self.onboardingRouter = nil
        
        viewController.dismiss(viewController: onboardingRouter.viewControllable,
                               animated: animated,
                               completion: completion)
    }
    
    // MARK: - Private
    
    private func routeToOnboarding() {
        guard onboardingRouter == nil else {
            // already presented
            return
        }
        
        let onboardingRouter = onboardingBuilder.build(withListener: viewController)
        self.onboardingRouter = onboardingRouter
        
        viewController.present(viewController: onboardingRouter.viewControllable,
                               animated: false,
                               completion: nil)
    }
    
    private let onboardingBuilder: OnboardingBuildable
    private var onboardingRouter: Routing?
    
    private let mainBuilder: MainBuildable
    private var mainViewController: ViewControllable?
}

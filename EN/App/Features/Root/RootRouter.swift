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
        guard let onboardingViewController = onboardingViewController else {
            completion()
            return
        }
        
        self.onboardingViewController = nil
        
        viewController.dismiss(viewController: onboardingViewController,
                               animated: animated,
                               completion: completion)
    }
    
    // MARK: - Private
    
    private func routeToOnboarding() {
        guard onboardingViewController == nil else {
            // already presented
            return
        }
        
        let onboardingViewController = onboardingBuilder.build(withListener: viewController)
        self.onboardingViewController = onboardingViewController
        
        viewController.present(viewController: onboardingViewController,
                               animated: false,
                               completion: nil)
    }
    
    private let onboardingBuilder: OnboardingBuildable
    private var onboardingViewController: ViewControllable?
    
    private let mainBuilder: MainBuildable
    private var mainViewController: ViewControllable?
}

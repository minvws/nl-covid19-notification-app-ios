/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// Use this to skip the onboarding flow
#if DEBUG
    let skipOnboarding = true
#else
    let skipOnboarding = false
#endif

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

    func embed(viewController: ViewControllable)
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
        if skipOnboarding {
            routeToMain()
        } else {
            routeToOnboarding()
        }
    }

    // MARK: - RootRouting

    func detachOnboardingAndRouteToMain(animated: Bool) {
        routeToMain()
        detachOnboarding(animated: animated)
    }

    // MARK: - Private

    private func routeToMain() {
        guard mainViewController == nil else {
            // already presented
            return
        }

        let mainViewController = self.mainBuilder.build()
        self.mainViewController = mainViewController

        self.viewController.embed(viewController: mainViewController)
    }

    private func detachOnboarding(animated: Bool) {
        guard let onboardingRouter = onboardingRouter else {
            return
        }

        self.onboardingRouter = nil

        viewController.dismiss(viewController: onboardingRouter.viewControllable,
            animated: animated,
            completion: nil)
    }

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

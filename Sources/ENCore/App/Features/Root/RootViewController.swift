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
    /// Presents the onboarding flow
    func routeToOnboarding()

    /// Detaches the onboarding feature and calls completion when done.
    /// When the onboarding flow is not attached, completion is called immediately
    ///
    /// - Parameter animated: Animates the dismissal animation
    func detachOnboardingAndRouteToMain(animated: Bool)

    /// Routes to the message flow
    func routeToMessage(title: String, body: String)

    /// Detaches the message flow
    ///
    /// - Parameter shouldDismissViewController: should the viewController actually be dismissed.
    func detachMessage(shouldDismissViewController: Bool)

    /// Detaches the message flow
    ///
    /// - Parameter shouldDismissViewController: should the viewController actually be dismissed.
    func detachCallGGD(shouldDismissViewController: Bool)

    /// Presents the update app screen
    func routeToUpdateApp(animated: Bool, appStoreURL: String?, minimumVersionMessage: String?)
}

final class RootViewController: ViewController, RootViewControllable {

    // MARK: - RootViewControllable

    weak var router: RootRouting?

    func presentInNavigationController(viewController: ViewControllable, animated: Bool) {
        let navigationController = NavigationController(rootViewController: viewController.uiviewController, theme: theme)

        if let presentationDelegate = viewController.uiviewController as? UIAdaptivePresentationControllerDelegate {
            navigationController.presentationController?.delegate = presentationDelegate
        }

        present(navigationController, animated: animated, completion: nil)
    }

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController,
                animated: animated,
                completion: completion)
    }

    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        if let navigationController = viewController.uiviewController.navigationController {
            navigationController.dismiss(animated: true, completion: completion)
        } else {
            viewController.uiviewController.dismiss(animated: animated, completion: completion)
        }
    }

    func embed(viewController: ViewControllable) {
        addChild(viewController.uiviewController)
        view.addSubview(viewController.uiviewController.view)
        viewController.uiviewController.view.frame = view.bounds
        viewController.uiviewController.didMove(toParent: self)
    }

    // MARK: - OnboardingListener

    func didCompleteOnboarding() {
        router?.detachOnboardingAndRouteToMain(animated: true)
    }

    // MARK: - MessageListner

    func messageWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachMessage(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - CallGGDListener

    func callGGDWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachCallGGD(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - DeveloperMenu Listener

    func developerMenuRequestsOnboardingFlow() {
        router?.routeToOnboarding()
    }

    func developerMenuRequestMessage(title: String, body: String) {
        router?.routeToMessage(title: title, body: body)
    }
}

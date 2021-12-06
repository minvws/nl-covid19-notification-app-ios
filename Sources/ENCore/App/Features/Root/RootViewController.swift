/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// Routing interface for the Root feature. Contains functions that are
/// called from `RootViewController`.
///
/// @mockable
protocol RootRouting: Routing {
    /// Presents the onboarding flow
    func routeToOnboarding()

    /// Schedule the EN background tasks
    func scheduleTasks()

    /// Detaches the onboarding feature and calls completion when done.
    /// When the onboarding flow is not attached, completion is called immediately
    ///
    /// - Parameter animated: Animates the dismissal animation
    func detachOnboardingAndRouteToMain(animated: Bool)

    /// Routes to the message flow
    func routeToMessage()

    /// Detaches the message flow
    ///
    /// - Parameter shouldDismissViewController: should the viewController actually be dismissed.
    func detachMessage(shouldDismissViewController: Bool)

    /// Detaches the message flow
    ///
    /// - Parameter shouldDismissViewController: should the viewController actually be dismissed.
    func detachCallGGD(shouldDismissViewController: Bool)

    /// Presents the update app screen
    func routeToUpdateApp(appStoreURL: String?, minimumVersionMessage: String?)

    /// Presents the update operating system screen
    func routeToUpdateOperatingSystem()

    /// Presents an webview
    func routeToWebview(url: URL)

    // Detaches the webview
    func detachWebview(shouldDismissViewController: Bool)

    func routeToSharing(shouldAnimate: Bool)
    func detachSharing(shouldHideViewController: Bool)
}

final class RootViewController: ViewController, RootViewControllable, Logging {

    func shareSheetDidComplete(shouldHideViewController: Bool) {
        router?.detachSharing(shouldHideViewController: shouldHideViewController)
    }

    func displayShareSheet(usingViewController viewcontroller: ViewController, completion: @escaping ((Bool) -> ())) {
        if let storeLink = URL(string: .shareAppUrl) {
            let activityVC = UIActivityViewController(activityItems: [.shareAppTitle as String, storeLink], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { _, completed, _, _ in
                completion(completed)
            }
            viewcontroller.present(activityVC, animated: true)
        } else {
            self.logError("Couldn't retreive a valid url")
        }
    }

    // MARK: - RootViewControllable

    weak var router: RootRouting?

    func presentInNavigationController(viewController: ViewControllable, animated: Bool, presentFullScreen: Bool) {
        let navigationController = NavigationController(rootViewController: viewController.uiviewController, theme: theme)

        if let presentationDelegate = viewController.uiviewController as? UIAdaptivePresentationControllerDelegate {
            navigationController.presentationController?.delegate = presentationDelegate
        }

        if presentFullScreen {
            navigationController.uiviewController.modalPresentationStyle = .fullScreen
        }

        if let presentedModal = presentedViewController {
            presentedModal.present(navigationController, animated: animated, completion: nil)
        } else {
            present(navigationController, animated: animated, completion: nil)
        }
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

        viewController.uiviewController.view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        viewController.uiviewController.didMove(toParent: self)
    }

    // MARK: - OnboardingListener

    func didCompleteOnboarding() {
        router?.detachOnboardingAndRouteToMain(animated: true)
    }

    func didCompleteConsent() {
        router?.scheduleTasks()
    }

    // MARK: - MessageListner

    func messageWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachMessage(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - CallGGDListener

    func callGGDWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachCallGGD(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - EndOfLifeListener

    func endOfLifeRequestsRedirect(to url: URL) {
        router?.routeToWebview(url: url)
    }

    // MARK: - WebviewListener

    func webviewRequestsDismissal(shouldHideViewController: Bool) {
        router?.detachWebview(shouldDismissViewController: shouldHideViewController)
    }

    // MARK: - DeveloperMenu Listener

    func developerMenuRequestsOnboardingFlow() {
        router?.routeToOnboarding()
    }

    func developerMenuRequestUpdateOperatingSystem() {
        router?.routeToUpdateOperatingSystem()
    }

    func developerMenuRequestUpdateApp(appStoreURL: String, minimumVersionMessage: String?) {
        router?.routeToUpdateApp(appStoreURL: appStoreURL, minimumVersionMessage: minimumVersionMessage)
    }
}

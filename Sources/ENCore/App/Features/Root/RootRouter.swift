/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Combine
import ENFoundation
import UIKit

/// Describes internal `RootViewController` functionality. Contains functions
/// that can be called from `RootRouter`. Should not be exposed
/// from `RootBuilder`. `RootBuilder` returns an `AppEntryPoint` instance instead
/// which is implemented by `RootRouter`.
///
/// @mockable
protocol RootViewControllable: ViewControllable, OnboardingListener, DeveloperMenuListener, MessageListener, CallGGDListener, UpdateAppListener, EndOfLifeListener, WebviewListener {
    var router: RootRouting? { get set }

    func presentInNavigationController(viewController: ViewControllable, animated: Bool, presentFullScreen: Bool)
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)

    func embed(viewController: ViewControllable)
}

final class RootRouter: Router<RootViewControllable>, RootRouting, AppEntryPoint, Logging {

    // MARK: - Initialisation

    init(viewController: RootViewControllable,
         onboardingBuilder: OnboardingBuildable,
         mainBuilder: MainBuildable,
         endOfLifeBuilder: EndOfLifeBuildable,
         messageBuilder: MessageBuildable,
         callGGDBuilder: CallGGDBuildable,
         exposureController: ExposureControlling,
         exposureStateStream: ExposureStateStreaming,
         developerMenuBuilder: DeveloperMenuBuildable,
         mutablePushNotificationStream: MutablePushNotificationStreaming,
         networkController: NetworkControlling,
         backgroundController: BackgroundControlling,
         updateAppBuilder: UpdateAppBuildable,
         webviewBuilder: WebviewBuildable,
         currentAppVersion: String?) {
        self.onboardingBuilder = onboardingBuilder
        self.mainBuilder = mainBuilder
        self.endOfLifeBuilder = endOfLifeBuilder
        self.messageBuilder = messageBuilder
        self.callGGDBuilder = callGGDBuilder
        self.developerMenuBuilder = developerMenuBuilder
        self.webviewBuilder = webviewBuilder

        self.exposureController = exposureController
        self.exposureStateStream = exposureStateStream

        self.mutablePushNotificationStream = mutablePushNotificationStream

        self.networkController = networkController
        self.backgroundController = backgroundController

        self.updateAppBuilder = updateAppBuilder
        self.currentAppVersion = currentAppVersion

        super.init(viewController: viewController)

        viewController.router = self
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - AppEntryPoint

    var uiviewController: UIViewController {
        return viewController.uiviewController
    }

    let mutablePushNotificationStream: MutablePushNotificationStreaming

    func start() {
        guard mainRouter == nil, onboardingRouter == nil else {
            // already started
            return
        }

        LogHandler.setup()

        /// Check if the app is the minimum version. If not, show the app update screen
        if let currentAppVersion = currentAppVersion {
            exposureController.getAppVersionInformation { appVersionInformation in
                guard let appVersionInformation = appVersionInformation else {
                    return
                }
                if appVersionInformation.minimumVersion.compare(currentAppVersion, options: .numeric) == .orderedDescending {
                    let minimumVersionMessage = appVersionInformation.minimumVersionMessage.isEmpty ? nil : appVersionInformation.minimumVersionMessage
                    self.routeToUpdateApp(animated: true,
                                          appStoreURL: appVersionInformation.appStoreURL,
                                          minimumVersionMessage: minimumVersionMessage)
                }
            }
        }

        if exposureController.didCompleteOnboarding {
            routeToMain()
            backgroundController.scheduleTasks()
        } else {
            routeToOnboarding()
        }

        exposureController.activate(inBackgroundMode: false)

        #if USE_DEVELOPER_MENU || DEBUG
            attachDeveloperMenu()
        #endif

        mutablePushNotificationStream
            .pushNotificationStream
            .sink { [weak self] (notificationRespone: UNNotificationResponse) in
                guard let strongSelf = self else {
                    return
                }

                self?.logDebug("Push Notification Identifier: \(notificationRespone.notification.request.identifier)")

                guard let identifier = PushNotificationIdentifier(rawValue: notificationRespone.notification.request.identifier) else {
                    return strongSelf.logError("Push notification for \(notificationRespone.notification.request.identifier) not handled")
                }

                switch identifier {
                case .exposure:
                    guard let lastExposureDate = strongSelf.exposureController.lastExposureDate else {
                        return strongSelf.logError("No Last Exposure Date to present")
                    }
                    strongSelf.routeToMessage(exposureDate: lastExposureDate)
                case .inactive:
                    () // Do nothing
                case .uploadFailed:
                    strongSelf.routeToCallGGD()
                case .enStatusDisabled:
                    () // Do nothing
                }
            }.store(in: &disposeBag)
    }

    func didBecomeActive() {

        exposureController.refreshStatus()

        exposureController
            .isAppDeactivated()
            .sink(receiveCompletion: { _ in
                // Do nothing
            }, receiveValue: { [weak self] isDectivated in
                if isDectivated {
                    self?.routeToEndOfLife()
                    self?.exposureController.deactivate()
                }
               })
            .store(in: &disposeBag)
    }

    func didEnterForeground() {
        guard mainRouter != nil || onboardingRouter != nil else {
            // not started yet
            return
        }

        exposureController.refreshStatus()
        exposureController
            .updateWhenRequired()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { _ in })
            .store(in: &disposeBag)

        networkController.startObservingNetworkReachability()
    }

    func didEnterBackground() {
        networkController.stopObservingNetworkReachability()
    }

    func handle(backgroundTask: BGTask) {
        backgroundController.handle(task: backgroundTask)
    }

    // MARK: - RootRouting

    func routeToOnboarding() {
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

    func detachOnboardingAndRouteToMain(animated: Bool) {
        exposureController.didCompleteOnboarding = true

        routeToMain()
        detachOnboarding(animated: animated)
    }

    func routeToMessage(exposureDate: Date) {
        guard messageViewController == nil else {
            return
        }
        let messageViewController = messageBuilder.build(withListener: viewController, exposureDate: exposureDate)
        self.messageViewController = messageViewController

        viewController.presentInNavigationController(viewController: messageViewController, animated: true, presentFullScreen: false)
    }

    func detachMessage(shouldDismissViewController: Bool) {
        guard let messageViewController = messageViewController else {
            return
        }
        self.messageViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: messageViewController, animated: true, completion: nil)
        }
    }

    func detachCallGGD(shouldDismissViewController: Bool) {
        guard let callGGDViewController = callGGDViewController else {
            return
        }
        self.callGGDViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: callGGDViewController, animated: true, completion: nil)
        }
    }

    func routeToUpdateApp(animated: Bool, appStoreURL: String?, minimumVersionMessage: String?) {
        guard updateAppViewController == nil else {
            return
        }
        let updateAppViewController = updateAppBuilder.build(withListener: viewController,
                                                             appStoreURL: appStoreURL,
                                                             minimumVersionMessage: minimumVersionMessage)
        self.updateAppViewController = updateAppViewController

        viewController.present(viewController: updateAppViewController, animated: animated, completion: nil)
    }

    func routeToWebview(url: URL) {
        guard webviewViewController == nil else { return }
        let webviewViewController = webviewBuilder.build(withListener: viewController, url: url)
        self.webviewViewController = webviewViewController

        viewController.presentInNavigationController(viewController: webviewViewController, animated: true, presentFullScreen: false)
    }

    func detachWebview(shouldDismissViewController: Bool) {
        guard let webviewViewController = webviewViewController else {
            return
        }
        self.webviewViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: webviewViewController, animated: true, completion: nil)
        }
    }

    // MARK: - Private

    private func routeToMain() {
        guard mainRouter == nil else {
            // already attached
            return
        }

        let mainRouter = self.mainBuilder.build()
        self.mainRouter = mainRouter

        self.viewController.embed(viewController: mainRouter.viewControllable)
    }

    private func routeToEndOfLife() {
        guard endOfLifeViewController == nil else {
            return
        }
        let endOfLifeViewController = endOfLifeBuilder.build(withListener: viewController)
        self.endOfLifeViewController = endOfLifeViewController
        self.viewController.presentInNavigationController(viewController: endOfLifeViewController, animated: false, presentFullScreen: true)
    }

    private func routeToCallGGD() {
        guard callGGDViewController == nil else {
            return
        }
        let callGGDViewController = callGGDBuilder.build(withListener: viewController)
        self.callGGDViewController = callGGDViewController

        viewController.presentInNavigationController(viewController: callGGDViewController, animated: true, presentFullScreen: false)
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

    private func attachDeveloperMenu() {
        guard developerMenuViewController == nil else { return }

        let developerMenuViewController = developerMenuBuilder.build(listener: viewController)
        self.developerMenuViewController = developerMenuViewController
    }

    private let currentAppVersion: String?

    private let networkController: NetworkControlling
    private let backgroundController: BackgroundControlling

    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming

    private let onboardingBuilder: OnboardingBuildable
    private var onboardingRouter: Routing?

    private let mainBuilder: MainBuildable
    private var mainRouter: Routing?

    private let endOfLifeBuilder: EndOfLifeBuildable
    private var endOfLifeViewController: ViewControllable?

    private let messageBuilder: MessageBuildable
    private var messageViewController: ViewControllable?

    private let callGGDBuilder: CallGGDBuildable
    private var callGGDViewController: ViewControllable?

    private var disposeBag = Set<AnyCancellable>()

    private let developerMenuBuilder: DeveloperMenuBuildable
    private var developerMenuViewController: ViewControllable?

    private let updateAppBuilder: UpdateAppBuildable
    private var updateAppViewController: ViewControllable?

    private let webviewBuilder: WebviewBuildable
    private var webviewViewController: ViewControllable?
}

private extension ExposureActiveState {
    var isAuthorized: Bool {
        switch self {
        case .active, .inactive, .authorizationDenied:
            return true
        case .notAuthorized:
            return false
        }
    }
}

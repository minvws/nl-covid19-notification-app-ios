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
/// @mockable(history: present = true; dismiss = true)
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
         launchScreenBuilder: LaunchScreenBuildable,
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
         userNotificationCenter: UserNotificationCenter,
         currentAppVersion: String) {
        self.launchScreenBuilder = launchScreenBuilder
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

        self.userNotificationCenter = userNotificationCenter

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

        // Copy of launch screen is shown to give the app time to determine the proper
        // screen to route to. If the network is slow this can take a few seconds.
        routeToLaunchScreen()

        routeToDeactivatedOrUpdateScreenIfNeeded { [weak self] didRoute in

            guard let strongSelf = self else { return }

            if strongSelf.exposureController.didCompleteOnboarding {
                strongSelf.backgroundController.scheduleTasks()
            }

            guard !didRoute else {
                return
            }

            strongSelf.detachLaunchScreenIfNeeded(animated: false) { [weak self] in

                guard let strongSelf = self else { return }

                if strongSelf.exposureController.didCompleteOnboarding {
                    strongSelf.routeToMain()
                } else {
                    strongSelf.routeToOnboarding()
                }
            }

            #if USE_DEVELOPER_MENU || DEBUG
                strongSelf.attachDeveloperMenu()
            #endif
        }

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
                case .appUpdateRequired:
                    () // Do nothing
                }
            }.store(in: &disposeBag)
    }

    func didBecomeActive() {

        exposureController.refreshStatus()

        if mainRouter != nil || onboardingRouter != nil {
            // App was started already. Check if we need to route to update / deactivated screen
            routeToDeactivatedOrUpdateScreenIfNeeded()
        }

        updateTreatmentPerspective()

        exposureController.updateLastLaunch()

        exposureController.clearUnseenExposureNotificationDate()

        removeNotificationsFromNotificationsCenter()
    }

    func didEnterForeground() {

        networkController.startObservingNetworkReachability()

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
    }

    func didEnterBackground() {
        networkController.stopObservingNetworkReachability()
    }

    func handle(backgroundTask: BGTask) {
        backgroundController.handle(task: backgroundTask)
    }

    // MARK: - RootRouting

    func routeToLaunchScreen() {
        guard launchScreenRouter == nil else {
            // already presented
            return
        }

        let router = launchScreenBuilder.build()
        self.launchScreenRouter = router

        viewController.present(viewController: router.viewControllable,
                               animated: false,
                               completion: nil)
    }

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

    func scheduleTasks() {
        backgroundController.scheduleTasks()
    }

    func detachOnboardingAndRouteToMain(animated: Bool) {
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

        /// Set the correct window hierachy
        detachOnboarding(animated: false)
        routeToMain()

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

    private func detachLaunchScreenIfNeeded(animated: Bool, completion: (() -> ())?) {
        guard let launchScreenRouter = launchScreenRouter else {
            completion?()
            return
        }

        self.launchScreenRouter = nil

        viewController.dismiss(viewController: launchScreenRouter.viewControllable,
                               animated: animated,
                               completion: completion)
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

    private func routeToDeactivatedOrUpdateScreenIfNeeded(completion: ((_ didRoute: Bool) -> ())? = nil) {

        exposureController
            .isAppDeactivated()
            .combineLatest(exposureController.appShouldUpdateCheck())
            .sink(receiveCompletion: { [weak self] exposureControllerCompletion in

                if exposureControllerCompletion == .failure(.networkUnreachable) ||
                    exposureControllerCompletion == .failure(.serverError) ||
                    exposureControllerCompletion == .failure(.internalError) ||
                    exposureControllerCompletion == .failure(.responseCached) {

                    self?.exposureController.activate(inBackgroundMode: false)

                    completion?(false)
                }
            }, receiveValue: { [weak self] isDeactivated, updateInformation in

                if isDeactivated {

                    self?.detachLaunchScreenIfNeeded(animated: false) {
                        self?.routeToEndOfLife()
                        self?.exposureController.deactivate()
                        self?.backgroundController.removeAllTasks()
                        completion?(true)
                    }

                    return
                }

                if updateInformation.shouldUpdate, let versionInformation = updateInformation.versionInformation {

                    let minimumVersionMessage = versionInformation.minimumVersionMessage.isEmpty ? nil : versionInformation.minimumVersionMessage

                    self?.detachLaunchScreenIfNeeded(animated: false) {
                        self?.routeToUpdateApp(animated: true, appStoreURL: versionInformation.appStoreURL, minimumVersionMessage: minimumVersionMessage)
                        completion?(true)
                    }
                    return
                }

                self?.exposureController.activate(inBackgroundMode: false)
                self?.backgroundController.performDecoySequenceIfNeeded()

                completion?(false)

            })
            .store(in: &disposeBag)
    }

    private func updateTreatmentPerspective() {

        exposureController
            .updateTreatmentPerspective()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { _ in })
            .store(in: &disposeBag)
    }

    private func removeNotificationsFromNotificationsCenter() {

        let identifiers = [
            PushNotificationIdentifier.exposure.rawValue,
            PushNotificationIdentifier.inactive.rawValue,
            PushNotificationIdentifier.enStatusDisabled.rawValue,
            PushNotificationIdentifier.appUpdateRequired.rawValue
        ]

        userNotificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private let currentAppVersion: String

    private let networkController: NetworkControlling
    private let backgroundController: BackgroundControlling

    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming

    private var launchScreenBuilder: LaunchScreenBuildable
    private var launchScreenRouter: Routing?

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

    private let userNotificationCenter: UserNotificationCenter
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

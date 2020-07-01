/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Combine
import UIKit

/// Describes internal `RootViewController` functionality. Contains functions
/// that can be called from `RootRouter`. Should not be exposed
/// from `RootBuilder`. `RootBuilder` returns an `AppEntryPoint` instance instead
/// which is implemented by `RootRouter`.
///
/// @mockable
protocol RootViewControllable: ViewControllable, OnboardingListener, DeveloperMenuListener, MessageListener, UpdateAppListener {
    var router: RootRouting? { get set }

    func presentInNavigationController(viewController: ViewControllable, animated: Bool)
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)

    func embed(viewController: ViewControllable)
}

final class RootRouter: Router<RootViewControllable>, RootRouting, AppEntryPoint {

    // MARK: - Initialisation

    init(viewController: RootViewControllable,
         onboardingBuilder: OnboardingBuildable,
         mainBuilder: MainBuildable,
         messageBuilder: MessageBuildable,
         exposureController: ExposureControlling,
         exposureStateStream: ExposureStateStreaming,
         developerMenuBuilder: DeveloperMenuBuildable,
         mutablePushNotificationStream: MutablePushNotificationStreaming,
         networkController: NetworkControlling,
         backgroundController: BackgroundControlling,
         updateAppBuilder: UpdateAppBuildable) {
        self.onboardingBuilder = onboardingBuilder
        self.mainBuilder = mainBuilder
        self.messageBuilder = messageBuilder
        self.developerMenuBuilder = developerMenuBuilder

        self.exposureController = exposureController
        self.exposureStateStream = exposureStateStream

        self.mutablePushNotificationStream = mutablePushNotificationStream

        self.networkController = networkController
        self.backgroundController = backgroundController

        self.updateAppBuilder = updateAppBuilder

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
        if let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            exposureController.getMinimumiOSVersion { version in
                if version?.compare(currentAppVersion, options: .numeric) == .orderedDescending {
                    self.routeToUpdateApp(animated: true)
                }
            }
        }

        exposureStateStream.exposureState.sink { [weak self] state in

            if state.activeState.isAuthorized {
                self?.routeToMain()
            } else {
                self?.routeToOnboarding()
            }
        }
        .store(in: &disposeBag)

        exposureController.activate()

        #if USE_DEVELOPER_MENU || DEBUG
            attachDeveloperMenu()
        #endif

        mutablePushNotificationStream
            .pushNotificationStream
            .sink { [weak self] (notificationRespone: UNNotificationResponse) in
                // TODO: Use the identifier to know which flow to launch
                let content = notificationRespone.notification.request.content
                self?.routeToMessage(title: content.title, body: content.body)
            }.store(in: &disposeBag)
    }

    func didEnterForeground() {
        exposureController.refreshStatus()
        exposureController.updateWhenRequired {}
        networkController.startObservingNetworkReachability()
    }

    func didEnterBackground() {
        networkController.stopObservingNetworkReachability()
        backgroundController.scheduleTasks()
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
        routeToMain()
        detachOnboarding(animated: animated)
    }

    func routeToMessage(title: String, body: String) {
        guard messageViewController == nil else {
            return
        }
        let messageViewController = messageBuilder.build(withListener: viewController, title: title, body: body)
        self.messageViewController = messageViewController

        viewController.presentInNavigationController(viewController: messageViewController, animated: true)
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

    func routeToUpdateApp(animated: Bool) {
        guard updateAppViewController == nil else {
            return
        }
        let updateAppViewController = updateAppBuilder.build(withListener: viewController)
        self.updateAppViewController = updateAppViewController

        viewController.present(viewController: updateAppViewController, animated: animated, completion: nil)
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

    private let networkController: NetworkControlling
    private let backgroundController: BackgroundControlling

    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming

    private let onboardingBuilder: OnboardingBuildable
    private var onboardingRouter: Routing?

    private let mainBuilder: MainBuildable
    private var mainRouter: Routing?

    private let messageBuilder: MessageBuildable
    private var messageViewController: ViewControllable?

    private var disposeBag = Set<AnyCancellable>()

    private let developerMenuBuilder: DeveloperMenuBuildable
    private var developerMenuViewController: ViewControllable?

    private let updateAppBuilder: UpdateAppBuildable
    private var updateAppViewController: ViewControllable?
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

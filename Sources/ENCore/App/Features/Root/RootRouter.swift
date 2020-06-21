/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import UIKit

#if DEBUG
    /// Use this to skip the onboarding flow
    let skipOnboarding = false
#else
    let skipOnboarding = false
#endif

/// Describes internal `RootViewController` functionality. Contains functions
/// that can be called from `RootRouter`. Should not be exposed
/// from `RootBuilder`. `RootBuilder` returns an `AppEntryPoint` instance instead
/// which is implemented by `RootRouter`.
///
/// @mockable
protocol RootViewControllable: ViewControllable, OnboardingListener, DeveloperMenuListener {
    var router: RootRouting? { get set }

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)

    func embed(viewController: ViewControllable)
}

final class RootRouter: Router<RootViewControllable>, RootRouting, AppEntryPoint {

    // MARK: - Initialisation

    init(viewController: RootViewControllable,
         onboardingBuilder: OnboardingBuildable,
         mainBuilder: MainBuildable,
         exposureController: ExposureControlling,
         exposureStateStream: ExposureStateStreaming,
         developerMenuBuilder: DeveloperMenuBuildable) {
        self.onboardingBuilder = onboardingBuilder
        self.mainBuilder = mainBuilder
        self.developerMenuBuilder = developerMenuBuilder

        self.exposureController = exposureController
        self.exposureStateStream = exposureStateStream

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

    func start() {
        guard mainRouter == nil, onboardingRouter == nil else {
            // already started
            return
        }

        exposureStateStream.exposureState.sink { [weak self] state in
            if state.activeState.isAuthorized {
                self?.routeToMain()

                self?.exposureController.requestLabConfirmationKey { result in
                    switch result {
                    case let .success(key):
                        self?.exposureController.requestUploadKeys(forLabConfirmationKey: key) { result in
                            print(result)
                        }
                    case .failure:
                        print("Cannot fetch key")
                    }
                }

            } else {
                self?.routeToOnboarding()
            }
        }
        .store(in: &disposeBag)

        exposureController.activate()

        #if USE_DEVELOPER_MENU || DEBUG
            attachDeveloperMenu()
        #endif
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

    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming

    private let onboardingBuilder: OnboardingBuildable
    private var onboardingRouter: Routing?

    private let mainBuilder: MainBuildable
    private var mainRouter: Routing?

    private var disposeBag = Set<AnyCancellable>()

    private let developerMenuBuilder: DeveloperMenuBuildable
    private var developerMenuViewController: ViewControllable?
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

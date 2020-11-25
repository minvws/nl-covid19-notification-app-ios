/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import XCTest

final class RootRouterTests: XCTestCase {
    private let viewController = RootViewControllableMock()
    private let onboardingBuilder = OnboardingBuildableMock()
    private let mainBuilder = MainBuildableMock()
    private let endOfLifeBuilder = EndOfLifeBuildableMock()
    private let messageBuilder = MessageBuildableMock()
    private let callGGDBuilder = CallGGDBuildableMock()
    private let developerMenuBuilder = DeveloperMenuBuildableMock()
    private let exposureController = ExposureControllingMock()
    private let exposureStateStream = ExposureStateStreamingMock()
    private let mutablePushNotificationStream = MutablePushNotificationStreamingMock()
    private let networkController = NetworkControllingMock()
    private let backgroundController = BackgroundControllingMock()
    private let updateAppBuilder = UpdateAppBuildableMock()
    private let webviewBuilder = WebviewBuildableMock()
    private let pushNotificationSubject = PassthroughSubject<UNNotificationResponse, Never>()
    private let userNotificationCenter = UserNotificationCenterMock()

    private var router: RootRouter!

    override func setUp() {
        super.setUp()

        exposureController.isAppDeactivatedHandler = {
            Just(false).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        exposureController.activateHandler = { _ in
            return Just(()).eraseToAnyPublisher()
        }

        exposureController.updateTreatmentPerspectiveHandler = {
            Just(TreatmentPerspective.emptyMessage).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        mutablePushNotificationStream.pushNotificationStream = pushNotificationSubject.eraseToAnyPublisher()

        router = RootRouter(viewController: viewController,
                            onboardingBuilder: onboardingBuilder,
                            mainBuilder: mainBuilder,
                            endOfLifeBuilder: endOfLifeBuilder,
                            messageBuilder: messageBuilder,
                            callGGDBuilder: callGGDBuilder,
                            exposureController: exposureController,
                            exposureStateStream: exposureStateStream,
                            developerMenuBuilder: developerMenuBuilder,
                            mutablePushNotificationStream: mutablePushNotificationStream,
                            networkController: networkController,
                            backgroundController: backgroundController,
                            updateAppBuilder: updateAppBuilder,
                            webviewBuilder: webviewBuilder,
                            userNotificationCenter: userNotificationCenter,
                            currentAppVersion: "1.0")
        set(activeState: .notAuthorized)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    func test_start_buildsAndPresentsOnboarding() {
        onboardingBuilder.buildHandler = { _ in return OnboardingRoutingMock() }

        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.start()

        XCTAssertEqual(onboardingBuilder.buildCallCount, 1)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 1)
        XCTAssertEqual(viewController.embedCallCount, 0)
    }

    func test_callStartTwice_doesNotPresentTwice() {
        onboardingBuilder.buildHandler = { _ in OnboardingRoutingMock() }

        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.start()
        router.start()

        XCTAssertEqual(onboardingBuilder.buildCallCount, 1)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 1)
        XCTAssertEqual(viewController.embedCallCount, 0)
    }

    func test_callStartWhenOnboardingCompleted_routesToMain() {
        exposureController.didCompleteOnboarding = true

        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.start()

        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 1)
    }

    func test_detachOnboardingAndRouteToMain_callsEmbedAndDismiss() {
        router.start()

        XCTAssertEqual(viewController.embedCallCount, 0)
        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachOnboardingAndRouteToMain(animated: true)

        XCTAssertEqual(viewController.embedCallCount, 1)
        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_detachOnboardingAndRouteToMain_marksOnboardingAsComplete() {
        router.start()

        XCTAssertEqual(exposureController.didCompleteOnboardingSetCallCount, 0)
        XCTAssertEqual(backgroundController.scheduleTasksCallCount, 0)

        router.detachOnboardingAndRouteToMain(animated: true)

        XCTAssertEqual(exposureController.didCompleteOnboardingSetCallCount, 1)
        XCTAssertEqual(backgroundController.scheduleTasksCallCount, 1)
    }

    func test_detachOnboardingAndRouteToMain_marksInteropAnnouncementAsSeen() {
        router.start()

        XCTAssertEqual(exposureController.seenAnnouncements, [])

        router.detachOnboardingAndRouteToMain(animated: true)

        XCTAssertEqual(exposureController.seenAnnouncements, [.interopAnnouncement])
    }

    func test_start_activatesExposureController() {
        XCTAssertEqual(exposureController.activateCallCount, 0)

        router.start()

        XCTAssertEqual(exposureController.activateCallCount, 1)
    }

    func test_callWebviewTwice_doesNotPresentTwice() {
        webviewBuilder.buildHandler = { _, _ in ViewControllableMock() }

        XCTAssertEqual(webviewBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)

        router.routeToWebview(url: URL(string: "https://coronamelder.nl")!)
        router.routeToWebview(url: URL(string: "https://coronamelder.nl")!)

        XCTAssertEqual(webviewBuilder.buildCallCount, 1)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentInNavigationControllerCallCount, 1)
    }

    func test_detachWebview_callsDismiss() {
        router.routeToWebview(url: URL(string: "https://coronamelder.nl")!)

        XCTAssertEqual(viewController.dismissCallCount, 0)

        router.detachWebview(shouldDismissViewController: true)

        XCTAssertEqual(viewController.dismissCallCount, 1)
    }

    func test_start_getMinimumVersion_showsUpdateAppViewController() {
        exposureController.getAppVersionInformationHandler = { handler in
            handler(.init(minimumVersion: "1.1",
                          minimumVersionMessage: "Version too low",
                          appStoreURL: "appstore://url"))
        }

        router.start()

        XCTAssertEqual(updateAppBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 2)
    }

    func test_start_appIsDeactivated_showsEndOfLifeViewController() {

        exposureController.isAppDeactivatedHandler = {
            Just(true).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        router.didBecomeActive()

        XCTAssertEqual(exposureController.deactivateCallCount, 1)
        XCTAssertEqual(endOfLifeBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentInNavigationControllerCallCount, 1)
    }

    func test_didEnterForeground_startsObservingNetworkReachability() {
        exposureController.updateWhenRequiredHandler = {
            Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        router.routeToOnboarding()

        XCTAssertEqual(networkController.startObservingNetworkReachabilityCallCount, 0)

        router.didEnterForeground()

        XCTAssertEqual(networkController.startObservingNetworkReachabilityCallCount, 1)
    }

    func test_didEnterBackground_startsObservingNetworkReachability() {
        XCTAssertEqual(networkController.stopObservingNetworkReachabilityCallCount, 0)

        router.didEnterBackground()

        XCTAssertEqual(networkController.stopObservingNetworkReachabilityCallCount, 1)
    }

    // MARK: - Private

    private func set(activeState: ExposureActiveState) {
        exposureStateStream.exposureState = Just(ExposureState(notifiedState: .notNotified,
                                                               activeState: activeState)).eraseToAnyPublisher()
    }
}

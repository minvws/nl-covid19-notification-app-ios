/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import XCTest

final class RootRouterTests: TestCase {
    private let viewController = RootViewControllableMock()
    private let launchScreenBuilder = LaunchScreenBuildableMock()
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
    private let userNotificationCenter = UserNotificationCenterMock()
    private let mutableNetworkStatusStream = MutableNetworkStatusStreamingMock()
    private let mockEnvironmentController = EnvironmentControllingMock()
    private let updateOperatingSystemBuilder = UpdateOperatingSystemBuildableMock()
    private var mockPauseController: PauseControllingMock!

    private var router: RootRouter!

    override func setUp() {
        super.setUp()

        mockEnvironmentController.supportsExposureNotification = true
        mockEnvironmentController.appSupportsiOSversion = true

        mockPauseController = PauseControllingMock()

        exposureController.isAppDeactivatedHandler = {
            .just(false)
        }

        exposureController.appShouldUpdateCheckHandler = {
            .just(AppUpdateInformation(shouldUpdate: false, versionInformation: nil))
        }

        exposureController.activateHandler = {
            .empty()
        }

        exposureController.updateTreatmentPerspectiveHandler = {
            .empty()
        }

        onboardingBuilder.buildHandler = { _ in
            OnboardingRoutingMock()
        }

        viewController.dismissHandler = { _, _, completion in
            completion?()
        }

        viewController.presentHandler = { _, _, completion in
            completion?()
        }

        router = RootRouter(viewController: viewController,
                            launchScreenBuilder: launchScreenBuilder,
                            onboardingBuilder: onboardingBuilder,
                            mainBuilder: mainBuilder,
                            endOfLifeBuilder: endOfLifeBuilder,
                            messageBuilder: messageBuilder,
                            callGGDBuilder: callGGDBuilder,
                            exposureController: exposureController,
                            exposureStateStream: exposureStateStream,
                            mutableNetworkStatusStream: mutableNetworkStatusStream,
                            developerMenuBuilder: developerMenuBuilder,
                            mutablePushNotificationStream: mutablePushNotificationStream,
                            networkController: networkController,
                            backgroundController: backgroundController,
                            updateAppBuilder: updateAppBuilder,
                            updateOperatingSystemBuilder: updateOperatingSystemBuilder,
                            webviewBuilder: webviewBuilder,
                            userNotificationCenter: userNotificationCenter,
                            currentAppVersion: "1.0",
                            environmentController: mockEnvironmentController,
                            pauseController: mockPauseController)
        set(activeState: .notAuthorized)
    }

    func test_init_setsRouterOnViewController() {
        XCTAssertEqual(viewController.routerSetCallCount, 1)
    }

    func test_start_buildsAndPresentsLaunchScreen() {
        let viewControllableMock = ViewControllableMock()

        launchScreenBuilder.buildHandler = { viewControllableMock }

        XCTAssertEqual(launchScreenBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)

        router.start()

        XCTAssertEqual(launchScreenBuilder.buildCallCount, 1)
        XCTAssertTrue(viewController.presentArgValues.first?.0 === viewControllableMock)
        XCTAssertEqual(viewController.presentCallCount, 2) // launch screen and onboarding screen

        // Test that the launchscreen is dismissed too
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertTrue(viewController.dismissArgValues.first?.0 === viewControllableMock)
    }

    func test_start_buildsAndPresentsOnboarding() {
        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.start()

        XCTAssertEqual(launchScreenBuilder.buildCallCount, 1)
        XCTAssertEqual(onboardingBuilder.buildCallCount, 1)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 2) // launch screen and onboarding screen
        XCTAssertEqual(viewController.embedCallCount, 0)
    }

    func test_start_registersBackgroundActivityHandler() {
        XCTAssertEqual(backgroundController.registerActivityHandleCallCount, 0)

        router.start()

        XCTAssertEqual(backgroundController.registerActivityHandleCallCount, 1)
    }

    func test_callStartTwice_doesNotPresentTwice() {
        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.start()
        router.start()

        XCTAssertEqual(launchScreenBuilder.buildCallCount, 1)
        XCTAssertEqual(onboardingBuilder.buildCallCount, 1)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 2)
        XCTAssertEqual(viewController.embedCallCount, 0)
    }

    func test_callStartWhenOnboardingCompleted_routesToMain() {
        exposureController.didCompleteOnboarding = true

        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.start()

        XCTAssertEqual(launchScreenBuilder.buildCallCount, 1)
        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
        XCTAssertEqual(viewController.embedCallCount, 1)
    }

    func test_detachOnboardingAndRouteToMain_callsEmbedAndDismiss() {
        router.start()

        XCTAssertEqual(viewController.embedCallCount, 0)
        XCTAssertEqual(viewController.dismissCallCount, 1)

        router.detachOnboardingAndRouteToMain(animated: true)

        XCTAssertEqual(viewController.embedCallCount, 1)
        XCTAssertEqual(viewController.dismissCallCount, 2)
    }

    func test_scheduleTasks() {
        router.scheduleTasks()
        XCTAssertEqual(backgroundController.scheduleTasksCallCount, 1)
    }

    func test_detachOnboardingAndRouteToMain_marksOnboardingAsComplete() {
        router.start()

        XCTAssertEqual(exposureController.didCompleteOnboardingSetCallCount, 0)
        XCTAssertEqual(backgroundController.scheduleTasksCallCount, 0)

        router.detachOnboardingAndRouteToMain(animated: true)
    }

    func test_detachOnboardingAndRouteToMain_marksInteropAnnouncementAsSeen() {
        router.start()

        XCTAssertEqual(exposureController.seenAnnouncements, [])

        router.detachOnboardingAndRouteToMain(animated: true)
    }

    func test_start_activatesExposureController() {
        XCTAssertEqual(exposureController.activateCallCount, 0)
        XCTAssertEqual(exposureController.postExposureManagerActivationCallCount, 0)
        XCTAssertEqual(backgroundController.performDecoySequenceIfNeededCallCount, 0)

        router.start()

        XCTAssertEqual(exposureController.activateCallCount, 1)
        XCTAssertEqual(exposureController.postExposureManagerActivationCallCount, 1)
        XCTAssertEqual(backgroundController.performDecoySequenceIfNeededCallCount, 1)
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

    func test_start_ENNotSupported_showsUpdateOperatingSystemViewController() {
        mockEnvironmentController.supportsExposureNotification = false

        router.start()

        XCTAssertEqual(launchScreenBuilder.buildCallCount, 0)
        XCTAssertEqual(updateOperatingSystemBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
    }

    func test_start_appNotSupportsiOSversion_showsUpdateOperatingSystemViewController() {
        mockEnvironmentController.appSupportsiOSversion = false

        router.start()

        XCTAssertEqual(launchScreenBuilder.buildCallCount, 0)
        XCTAssertEqual(updateOperatingSystemBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 1)
    }

    func test_start_getMinimumVersion_showsUpdateAppViewController() {
        let appVersionInformation = ExposureDataAppVersionInformation(
            minimumVersion: "1.1",
            minimumVersionMessage: "Version too low",
            appStoreURL: "appstore://url"
        )

        exposureController.appShouldUpdateCheckHandler = {
            .just(AppUpdateInformation(shouldUpdate: true, versionInformation: appVersionInformation))
        }

        router.start()

        XCTAssertEqual(launchScreenBuilder.buildCallCount, 1)
        XCTAssertEqual(updateAppBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentCallCount, 2)
    }

    func test_start_appIsDeactivated_showsEndOfLifeViewController() {
        // Initial call to setup normal routing. didBecomeActive only checks End Of Life if
        // there is already a router installed (the app startup routine was already executed)
        router.start()

        exposureController.isAppDeactivatedHandler = {
            .just(true)
        }

        XCTAssertEqual(exposureController.deactivateCallCount, 0)
        XCTAssertEqual(endOfLifeBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentInNavigationControllerCallCount, 0)

        router.didBecomeActive()

        XCTAssertEqual(exposureController.deactivateCallCount, 1)
        XCTAssertEqual(endOfLifeBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentInNavigationControllerCallCount, 1)
    }

    func test_didBecomeActive_shouldAlsoPerformForegroundActionsOniOS12() {
        mockEnvironmentController.isiOS12 = true
        exposureController.updateWhenRequiredHandler = {
            .empty()
        }

        XCTAssertEqual(exposureController.refreshStatusCallCount, 0)
        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 0)

        router.start()

        XCTAssertEqual(exposureController.refreshStatusCallCount, 0)
        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 0)

        router.didBecomeActive()

        XCTAssertEqual(exposureController.refreshStatusCallCount, 2)
        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 1)
    }

    func test_didEnterForeground_startsObservingNetworkReachability() {
        exposureController.updateWhenRequiredHandler = {
            .empty()
        }

        XCTAssertEqual(mutableNetworkStatusStream.startObservingNetworkReachabilityCallCount, 0)

        router.didEnterForeground()

        XCTAssertEqual(mutableNetworkStatusStream.startObservingNetworkReachabilityCallCount, 1)
    }

    func test_didEnterBackground_startsObservingNetworkReachability() {
        XCTAssertEqual(mutableNetworkStatusStream.stopObservingNetworkReachabilityCallCount, 0)

        router.didEnterBackground()

        XCTAssertEqual(mutableNetworkStatusStream.stopObservingNetworkReachabilityCallCount, 1)
    }

    func test_didEnterForeground_callsRefreshStatus() {
        exposureController.updateWhenRequiredHandler = { .empty() }

        // Required to attach main router
        router.start()

        XCTAssertEqual(exposureController.refreshStatusCallCount, 0)

        router.didEnterForeground()

        XCTAssertEqual(exposureController.refreshStatusCallCount, 1)
    }

    func test_didEnterForeground_callsUpdateWhenRequired() {
        exposureController.updateWhenRequiredHandler = { .empty() }

        // Required to attach main router
        router.start()

        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 0)

        router.didEnterForeground()

        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 1)
    }

    // MARK: - Handling Notifications

    func test_receivingUploadFailedNotification_shouldRouteToCallGGD() {
        exposureController.didCompleteOnboarding = true

        let mockCallGGDViewController = ViewControllableMock()
        callGGDBuilder.buildHandler = { _ in
            mockCallGGDViewController
        }
        mutablePushNotificationStream.pushNotificationStream = .just(.uploadFailed)

        router.start()

        let lastPresenterViewController = viewController.presentInNavigationControllerArgValues.last?.0

        XCTAssertTrue(lastPresenterViewController === mockCallGGDViewController)
    }

    func test_receivingExposureNotification_shouldRouteToMessage() {
        exposureController.didCompleteOnboarding = true
        exposureController.lastExposureDate = currentDate()

        let messageBuilderExpectation = expectation(description: "messageBuilder")

        let mockMessageViewController = ViewControllableMock()
        messageBuilder.buildHandler = { _ in
            messageBuilderExpectation.fulfill()
            return mockMessageViewController
        }
        mutablePushNotificationStream.pushNotificationStream = .just(.exposure)

        router.start()

        let lastPresenterViewController = viewController.presentInNavigationControllerArgValues.last?.0

        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertTrue(lastPresenterViewController === mockMessageViewController)
    }

    // MARK: - Private

    private func set(activeState: ExposureActiveState) {
        exposureStateStream.exposureState = .just(ExposureState(notifiedState: .notNotified,
                                                                activeState: activeState))
    }
}

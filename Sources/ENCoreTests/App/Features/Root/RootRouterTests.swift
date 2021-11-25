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
    private let userNotificationController = UserNotificationControllingMock()
    private let mutableNetworkStatusStream = MutableNetworkStatusStreamingMock()
    private let mockEnvironmentController = EnvironmentControllingMock()
    private let updateOperatingSystemBuilder = UpdateOperatingSystemBuildableMock()
    private var mockPauseController: PauseControllingMock!
    private var mockShareBuilder = ShareSheetBuildableMock()

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
                            userNotificationController: userNotificationController,
                            currentAppVersion: "1.0",
                            environmentController: mockEnvironmentController,
                            pauseController: mockPauseController,
                            shareBuilder: mockShareBuilder)
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
        let viewcontrollerPresentExpectation = expectation(description: "viewControllerPresented")
        viewcontrollerPresentExpectation.expectedFulfillmentCount = 2

        viewController.presentHandler = { _, _, completion in
            viewcontrollerPresentExpectation.fulfill()
            completion?()
        }

        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.start()

        waitForExpectations(timeout: 2, handler: nil)
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
        let viewcontrollerPresentExpectation = expectation(description: "viewControllerPresented")
        viewcontrollerPresentExpectation.expectedFulfillmentCount = 2

        viewController.presentHandler = { _, _, completion in
            viewcontrollerPresentExpectation.fulfill()
            completion?()
        }

        XCTAssertEqual(onboardingBuilder.buildCallCount, 0)
        XCTAssertEqual(mainBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentCallCount, 0)
        XCTAssertEqual(viewController.embedCallCount, 0)

        router.start()
        router.start()

        waitForExpectations(timeout: 2, handler: nil)
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
        waitForRouterStart()

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
        waitForRouterStart()

        XCTAssertEqual(exposureController.didCompleteOnboardingSetCallCount, 0)
        XCTAssertEqual(backgroundController.scheduleTasksCallCount, 0)

        router.detachOnboardingAndRouteToMain(animated: true)
    }

    func test_detachOnboardingAndRouteToMain_marksInteropAnnouncementAsSeen() {
        waitForRouterStart()

        XCTAssertEqual(exposureController.seenAnnouncements, [])

        router.detachOnboardingAndRouteToMain(animated: true)
    }

    func test_start_activatesExposureController() {
        let postExposureManagerActivationExpectation = expectation(description: "postExposureManagerActivation")
        let decoySequenceExpectation = expectation(description: "decoySequence")

        XCTAssertEqual(exposureController.activateCallCount, 0)
        XCTAssertEqual(exposureController.postExposureManagerActivationCallCount, 0)
        XCTAssertEqual(backgroundController.performDecoySequenceIfNeededCallCount, 0)

        exposureController.postExposureManagerActivationHandler = { postExposureManagerActivationExpectation.fulfill() }
        backgroundController.performDecoySequenceIfNeededHandler = { decoySequenceExpectation.fulfill() }

        waitForRouterStart()

        waitForExpectations(timeout: 2, handler: nil)

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
        let viewcontrollerPresentExpectation = expectation(description: "viewControllerPresented")

        viewController.presentInNavigationControllerHandler = { _, _, _ in
            viewcontrollerPresentExpectation.fulfill()
        }

        exposureController.updateWhenRequiredHandler = { .empty() }

        waitForRouterStart()

        exposureController.isAppDeactivatedHandler = {
            .just(true)
        }

        XCTAssertEqual(exposureController.deactivateCallCount, 0)
        XCTAssertEqual(endOfLifeBuilder.buildCallCount, 0)
        XCTAssertEqual(viewController.presentInNavigationControllerCallCount, 0)

        router.didBecomeActive()

        wait(for: [viewcontrollerPresentExpectation], timeout: 2)

        XCTAssertEqual(exposureController.deactivateCallCount, 1)
        XCTAssertEqual(endOfLifeBuilder.buildCallCount, 1)
        XCTAssertEqual(viewController.presentInNavigationControllerCallCount, 1)
    }

    func test_didBecomeActive_shouldAlsoPerformForegroundActionsOniOS12() {
        let completionExpectation = expectation(description: "completion")
        let updateWhenRequiredExpectation = expectation(description: "updateWhenRequired")

        mockEnvironmentController.isiOS12 = true
        exposureController.updateWhenRequiredHandler = {
            updateWhenRequiredExpectation.fulfill()
            return .empty()
        }

        XCTAssertEqual(exposureController.refreshStatusCallCount, 0)
        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 0)

        waitForRouterStart()

        XCTAssertEqual(exposureController.refreshStatusCallCount, 0)
        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 0)

        router.didBecomeActive()

        wait(for: [updateWhenRequiredExpectation], timeout: 2)
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertEqual(self.exposureController.refreshStatusCallCount, 2)
            XCTAssertEqual(self.exposureController.updateWhenRequiredCallCount, 1)
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
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

        waitForRouterStart()

        XCTAssertEqual(exposureController.refreshStatusCallCount, 0)

        router.didEnterForeground()

        XCTAssertEqual(exposureController.refreshStatusCallCount, 1)
    }

    func test_didEnterForeground_callsUpdateWhenRequired() {
        let completionExpectation = expectation(description: "completion")

        exposureController.updateWhenRequiredHandler = {
            XCTAssertTrue(Thread.current.qualityOfService == .userInitiated)
            return .empty()
        }

        waitForRouterStart()

        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 0)

        router.didEnterForeground()

        DispatchQueue.global(qos: .userInitiated).async {
            completionExpectation.fulfill()
        }

        waitForExpectations()

        XCTAssertEqual(exposureController.updateWhenRequiredCallCount, 1)
    }

    // MARK: - Handling Notifications

    func test_receivingUploadFailedNotification_shouldRouteToCallGGD() {
        let viewcontrollerPresentExpectation = expectation(description: "viewControllerPresented")
        viewController.presentInNavigationControllerHandler = { _, _, _ in
            viewcontrollerPresentExpectation.fulfill()
        }

        exposureController.didCompleteOnboarding = true

        let mockCallGGDViewController = ViewControllableMock()
        callGGDBuilder.buildHandler = { _ in
            mockCallGGDViewController
        }
        mutablePushNotificationStream.pushNotificationStream = .just(.uploadFailed)

        router.start()

        waitForExpectations(timeout: 2, handler: nil)
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

    private func waitForRouterStart() {
        let routerStartExpectation = expectation(description: "routerStartExpectation")

        let onboardingViewControllableMock = ViewControllableMock()
        onboardingBuilder.buildHandler = { _ in
            OnboardingRoutingMock(viewControllable: onboardingViewControllableMock)
        }

        // Wait for viewcontroller to be presented so we're sure that there is a router set
        viewController.presentHandler = { presentedViewController, _, completion in

            if presentedViewController === onboardingViewControllableMock {
                routerStartExpectation.fulfill()
            }

            completion?()
        }

        // Initial call to setup normal routing. didBecomeActive only checks End Of Life if
        // there is already a router installed (the app startup routine was already executed)
        router.start()

        wait(for: [routerStartExpectation], timeout: 10)
    }
}

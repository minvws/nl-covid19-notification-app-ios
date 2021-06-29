/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import RxSwift
import XCTest

class OnboardingConsentManagerTests: TestCase {

    private var sut: OnboardingConsentManager!
    private var mockExposureStateStream: ExposureStateStreamingMock!
    private var mockExposureController: ExposureControllingMock!
    private var mockExposureState = BehaviorSubject<ExposureState>(value: .init(notifiedState: .notNotified, activeState: .active))
    private var mockUserNotificationController: UserNotificationControllingMock!
    private var mockApplicationController: ApplicationControllingMock!
    
    override func setUp() {
        super.setUp()
        mockExposureStateStream = ExposureStateStreamingMock()
        mockExposureController = ExposureControllingMock()
        mockUserNotificationController = UserNotificationControllingMock()
        mockApplicationController = ApplicationControllingMock()

        mockExposureStateStream.exposureState = mockExposureState
        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .notAuthorized)
        
        sut = OnboardingConsentManager(exposureStateStream: mockExposureStateStream,
                                       exposureController: mockExposureController,
                                       userNotificationController: mockUserNotificationController,
                                       applicationController: mockApplicationController,
                                       theme: theme)
    }

    func test_getNextConsentStep_afterEN_withActiveState() {
        let completionExpectation = expectation(description: "completion")

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .active))

        let currentStep: OnboardingConsentStep.Index = .en
        let skippedCurrentStep: Bool = false
        let completion: (OnboardingConsentStep.Index?) -> () = { stepIndex in
            XCTAssertTrue(Thread.current.isMainThread)
            XCTAssertEqual(stepIndex, .share)
            completionExpectation.fulfill()
        }

        sut.getNextConsentStep(currentStep, skippedCurrentStep: skippedCurrentStep, completion: completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getNextConsentStep_afterEN_withBluetoothOffState() {
        let completionExpectation = expectation(description: "completion")

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .inactive(.bluetoothOff)))

        let currentStep: OnboardingConsentStep.Index = .en
        let skippedCurrentStep: Bool = false
        let completion: (OnboardingConsentStep.Index?) -> () = { stepIndex in
            XCTAssertEqual(stepIndex, .bluetooth)
            completionExpectation.fulfill()
        }

        sut.getNextConsentStep(currentStep, skippedCurrentStep: skippedCurrentStep, completion: completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getNextConsentStep_afterBluetooth() {
        let completionExpectation = expectation(description: "completion")

        let currentStep: OnboardingConsentStep.Index = .bluetooth
        let skippedCurrentStep: Bool = false
        let completion: (OnboardingConsentStep.Index?) -> () = { stepIndex in
            XCTAssertEqual(stepIndex, .share)
            completionExpectation.fulfill()
        }

        sut.getNextConsentStep(currentStep, skippedCurrentStep: skippedCurrentStep, completion: completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getNextConsentStep_afterShare() {
        let completionExpectation = expectation(description: "completion")

        let currentStep: OnboardingConsentStep.Index = .share
        let skippedCurrentStep: Bool = false
        let completion: (OnboardingConsentStep.Index?) -> () = { stepIndex in
            XCTAssertNil(stepIndex)
            completionExpectation.fulfill()
        }

        sut.getNextConsentStep(currentStep, skippedCurrentStep: skippedCurrentStep, completion: completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_isNotificationAuthorizationAsked_stateActive() {
        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .active)

        let result = sut.isNotificationAuthorizationAsked()
        
        XCTAssertTrue(result)
    }

    func test_isNotificationAuthorizationAsked_stateAuthorizationDenied() {
        
        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .authorizationDenied)

        let result = sut.isNotificationAuthorizationAsked()
        
        XCTAssertTrue(result)
    }

    func test_isNotificationAuthorizationAsked_stateNotAuthorized() {
        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .notAuthorized)

        let result = sut.isNotificationAuthorizationAsked()
        
        XCTAssertFalse(result)
    }

    func test_isNotificationAuthorizationAsked_stateInactiveDisabled() {
        
        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .inactive(.disabled))

        let result = sut.isNotificationAuthorizationAsked()
        
        XCTAssertFalse(result)
    }
    
    func test_isBluetoothEnabled_withBluetoothOn() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .active)
        
        // Act
        sut.isBluetoothEnabled { (isEnabled) in
            XCTAssertTrue(isEnabled)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_isBluetoothEnabled_withBluetoothOff() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .inactive(.bluetoothOff))
        
        // Act
        sut.isBluetoothEnabled { (isEnabled) in
            XCTAssertFalse(isEnabled)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_askEnableExposureNotifications_alreadyActive() {
        let completionExpectation = expectation(description: "completion")

        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .active)
        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .active))

        let completion: (ExposureActiveState) -> () = { state in
            XCTAssertTrue(Thread.current.isMainThread)
            XCTAssertEqual(state, .active)
            completionExpectation.fulfill()
        }

        sut.askEnableExposureNotifications(completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_askEnableExposureNotifications_activatedAfterRequestingPermission() {
        let completionExpectation = expectation(description: "completion")

        mockExposureStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .inactive(.disabled))
        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .inactive(.disabled)))

        let completion: (ExposureActiveState) -> () = { state in
            XCTAssertEqual(state, .active)
            completionExpectation.fulfill()
        }

        sut.askEnableExposureNotifications(completion)

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .active))

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertEqual(mockExposureController.requestExposureNotificationPermissionCallCount, 1)
    }

    func test_askEnableExposureNotifications_shouldOnlyCompleteOnce() {
        let completionExpectation = expectation(description: "completion")

        let completion: (ExposureActiveState) -> () = { state in
            completionExpectation.fulfill()
        }

        sut.askEnableExposureNotifications(completion)

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .inactive(.pushNotifications)))
        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .active))

        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func test_goToBluetoothSettings() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        XCTAssertEqual(mockApplicationController.canOpenURLCallCount, 0)
        XCTAssertEqual(mockApplicationController.openCallCount, 0)
        
        mockApplicationController.canOpenURLHandler = { url in
            XCTAssertEqual(url.absoluteString, UIApplication.openSettingsURLString)
            return true
        }
        
        // Act
        sut.goToBluetoothSettings {
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockApplicationController.canOpenURLCallCount, 1)
        XCTAssertEqual(mockApplicationController.openCallCount, 1)
    }

    func test_askNotificationsAuthorization_shouldCallUserNotificationCenter() {
        let completionExpectation = expectation(description: "completion")
        let userNotificationExpectation = expectation(description: "userNotificationExpectation")
        mockUserNotificationController.requestNotificationPermissionHandler = { completion in
            userNotificationExpectation.fulfill()
            completion()
        }

        sut.askNotificationsAuthorization {
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockUserNotificationController.requestNotificationPermissionCallCount, 1)
    }
    
    func test_getAppStoreUrl_shouldCallExposureController() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        mockExposureController.getAppVersionInformationHandler = { completion in
            completion(ExposureDataAppVersionInformation(
                minimumVersion: "",
                minimumVersionMessage: "",
                appStoreURL: "http://www.someAppStoreURL.com"))
        }
        
        // Act
        sut.getAppStoreUrl { (urlString) in
            XCTAssertEqual(urlString, "http://www.someAppStoreURL.com")
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_didCompleteConsent_shouldCompleteOnboardingInExposureController() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        XCTAssertFalse(mockExposureController.didCompleteOnboarding)
        
        // Act
        sut.didCompleteConsent()
        
        // Assert
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertTrue(self.mockExposureController.didCompleteOnboarding)
            XCTAssertEqual(self.mockExposureController.seenAnnouncements, [])
            completionExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_getStep() {
        XCTAssertEqual(sut.getStep(0)?.step, .en)
        XCTAssertEqual(sut.getStep(0)?.attributedTitle.string, .onboardingPermissionsTitle)
        
        XCTAssertEqual(sut.getStep(1)?.step, .bluetooth)
        XCTAssertEqual(sut.getStep(1)?.attributedTitle.string, .consentStep2Title)
                       
        XCTAssertEqual(sut.getStep(2)?.step, .share)
        XCTAssertEqual(sut.getStep(2)?.attributedTitle.string, .consentStep4Title)
        
        XCTAssertNil(sut.getStep(3))
    }
}

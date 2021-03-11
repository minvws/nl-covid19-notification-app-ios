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

    override func setUpWithError() throws {
        mockExposureStateStream = ExposureStateStreamingMock()
        mockExposureController = ExposureControllingMock()
        mockUserNotificationController = UserNotificationControllingMock()

        mockExposureStateStream.exposureState = mockExposureState

        sut = OnboardingConsentManager(exposureStateStream: mockExposureStateStream,
                                       exposureController: mockExposureController,
                                       userNotificationController: mockUserNotificationController,
                                       theme: theme)
    }

    func test_getNextConsentStep_afterEN_withActiveState() {
        let completionExpectation = expectation(description: "completion")

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .active))

        let currentStep: OnboardingConsentStep.Index = .en
        let skippedCurrentStep: Bool = false
        let completion: (OnboardingConsentStep.Index?) -> () = { stepIndex in
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
        let completionExpectation = expectation(description: "completion")

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .active))

        let completion: (Bool) -> () = { wasAsked in
            XCTAssertTrue(wasAsked)
            completionExpectation.fulfill()
        }

        sut.isNotificationAuthorizationAsked(completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_isNotificationAuthorizationAsked_stateAuthorizationDenied() {
        let completionExpectation = expectation(description: "completion")

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .authorizationDenied))

        let completion: (Bool) -> () = { wasAsked in
            XCTAssertTrue(wasAsked)
            completionExpectation.fulfill()
        }

        sut.isNotificationAuthorizationAsked(completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_isNotificationAuthorizationAsked_stateNotAuthorized() {
        let completionExpectation = expectation(description: "completion")

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .notAuthorized))

        let completion: (Bool) -> () = { wasAsked in
            XCTAssertFalse(wasAsked)
            completionExpectation.fulfill()
        }

        sut.isNotificationAuthorizationAsked(completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_isNotificationAuthorizationAsked_stateInactiveDisabled() {
        let completionExpectation = expectation(description: "completion")

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .inactive(.disabled)))

        let completion: (Bool) -> () = { wasAsked in
            XCTAssertFalse(wasAsked)
            completionExpectation.fulfill()
        }

        sut.isNotificationAuthorizationAsked(completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_askEnableExposureNotifications_alreadyActive() {
        let completionExpectation = expectation(description: "completion")

        mockExposureState.onNext(.init(notifiedState: .notNotified, activeState: .active))

        let completion: (ExposureActiveState) -> () = { state in
            XCTAssertEqual(state, .active)
            completionExpectation.fulfill()
        }

        sut.askEnableExposureNotifications(completion)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_askEnableExposureNotifications_activatedAfterRequestingPermission() {
        let completionExpectation = expectation(description: "completion")

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
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class OnboardingViewControllerTests: TestCase {
    private var sut: OnboardingViewController!
    private var mockOnboardingRouter: OnboardingRoutingMock!
    private var mockOnboardingListener: OnboardingListenerMock!
    private var mockOnboardingConsentManager: OnboardingConsentManagingMock!

    override func setUp() {
        super.setUp()

        mockOnboardingRouter = OnboardingRoutingMock()
        mockOnboardingListener = OnboardingListenerMock()
        mockOnboardingConsentManager = OnboardingConsentManagingMock()

        sut = OnboardingViewController(onboardingConsentManager: mockOnboardingConsentManager,
                                       listener: mockOnboardingListener,
                                       theme: theme)
        sut.router = mockOnboardingRouter
    }

    func test_helpRequestsEnableApp_shouldCompleteConsent() {
        mockOnboardingConsentManager.askNotificationsAuthorizationHandler = { completion in
            completion()
        }

        mockOnboardingConsentManager.askEnableExposureNotificationsHandler = { completion in
            completion(.active)
        }

        sut.helpRequestsEnableApp()

        XCTAssertEqual(mockOnboardingConsentManager.askNotificationsAuthorizationCallCount, 1)
        XCTAssertEqual(mockOnboardingConsentManager.askEnableExposureNotificationsCallCount, 1)

        XCTAssertEqual(mockOnboardingConsentManager.didCompleteConsentCallCount, 1)
    }

    func test_helpRequestsEnableApp_unAuthorized_shouldCompleteOnboarding() {
        mockOnboardingConsentManager.askNotificationsAuthorizationHandler = { completion in
            completion()
        }

        mockOnboardingConsentManager.askEnableExposureNotificationsHandler = { completion in
            completion(.notAuthorized)
        }

        sut.helpRequestsEnableApp()

        XCTAssertEqual(mockOnboardingConsentManager.askNotificationsAuthorizationCallCount, 1)
        XCTAssertEqual(mockOnboardingConsentManager.askEnableExposureNotificationsCallCount, 1)

        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 1)
    }

    func test_helpRequestsEnableApp_nextStep_shouldRouteToConsent() {
        mockOnboardingConsentManager.askNotificationsAuthorizationHandler = { completion in
            completion()
        }

        mockOnboardingConsentManager.askEnableExposureNotificationsHandler = { completion in
            completion(.active)
        }

        mockOnboardingConsentManager.getNextConsentStepHandler = { currentStep, skippedCurrentStep, completion in
            XCTAssertEqual(currentStep, .en)
            XCTAssertFalse(skippedCurrentStep)
            completion(.share)
        }

        sut.helpRequestsEnableApp()

        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 1)
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexArgValues.first?.0, OnboardingConsentStep.Index.share.rawValue)
    }

    func test_helpRequestsEnableApp_NoNextStep_shouldCompleteOnboarding() {
        mockOnboardingConsentManager.askNotificationsAuthorizationHandler = { completion in
            completion()
        }

        mockOnboardingConsentManager.askEnableExposureNotificationsHandler = { completion in
            completion(.active)
        }

        mockOnboardingConsentManager.getNextConsentStepHandler = { currentStep, skippedCurrentStep, completion in
            XCTAssertEqual(currentStep, .en)
            XCTAssertFalse(skippedCurrentStep)
            completion(nil)
        }

        sut.helpRequestsEnableApp()

        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 1)
    }
}

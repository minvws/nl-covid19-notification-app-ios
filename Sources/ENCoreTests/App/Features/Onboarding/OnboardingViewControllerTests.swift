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
    
    func test_onboardingStepsDidComplete_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToPrivacyAgreementCallCount, 0)
        
        // Act
        sut.onboardingStepsDidComplete()
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.routeToPrivacyAgreementCallCount, 1)
    }
    
    func test_nextStepAtIndex_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToStepCallCount, 0)
        
        // Act
        sut.nextStepAtIndex(10)
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.routeToStepCallCount, 1)        
    }
    
    func test_consentClose_shouldCallListener() {
        // Arrange
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 0)
        
        // Act
        sut.consentClose()
        
        // Assert
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 1)
    }
    
    func test_consentRequest_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 0)
        
        // Act
        sut.consentRequest(step: .bluetooth)
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 1)
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexArgValues.first!.0, OnboardingConsentStep.Index.bluetooth.rawValue)
        XCTAssertTrue(mockOnboardingRouter.routeToConsentWithIndexArgValues.first!.1)
    }
    
    func test_consentRequest_shareStepShouldCompleteConsent() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 0)
        XCTAssertEqual(mockOnboardingConsentManager.didCompleteConsentCallCount, 0)
        XCTAssertEqual(mockOnboardingListener.didCompleteConsentCallCount, 0)
        
        // Act
        sut.consentRequest(step: .share)
        
        // Assert
        XCTAssertEqual(mockOnboardingConsentManager.didCompleteConsentCallCount, 1)
        XCTAssertEqual(mockOnboardingListener.didCompleteConsentCallCount, 1)
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 1)
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexArgValues.first!.0, OnboardingConsentStep.Index.share.rawValue)
        XCTAssertTrue(mockOnboardingRouter.routeToConsentWithIndexArgValues.first!.1)
    }
    
    func test_privacyAgreementDidComplete_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToConsentCallCount, 0)
        
        // Act
        sut.privacyAgreementDidComplete()
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.routeToConsentCallCount, 1)        
    }
    
    func test_privacyAgreementRequestsRedirect_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToWebviewCallCount, 0)
        let url = URL(string: "http://www.someurl.com")!
        
        // Act
        sut.privacyAgreementRequestsRedirect(to: url)
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.routeToWebviewCallCount, 1)
        XCTAssertEqual(mockOnboardingRouter.routeToWebviewArgValues.first!, url)
    }
    
    func test_webviewRequestsDismissal_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.dismissWebviewCallCount, 0)
        
        // Act
        sut.webviewRequestsDismissal(shouldHideViewController: true)
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.dismissWebviewCallCount, 1)
        XCTAssertTrue(mockOnboardingRouter.dismissWebviewArgValues.first!)
    }
    
    func test_displayHelp_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToHelpCallCount, 0)
        
        // Act
        sut.displayHelp()
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.routeToHelpCallCount, 1)
    }
    
    func test_displayBluetoothSettings_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToBluetoothSettingsCallCount, 0)
        
        // Act
        sut.displayBluetoothSettings()
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.routeToBluetoothSettingsCallCount, 1)
    }
    
    func test_isBluetoothEnabled_shouldCallConsentManager() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        XCTAssertEqual(mockOnboardingConsentManager.isBluetoothEnabledCallCount, 0)
        mockOnboardingConsentManager.isBluetoothEnabledHandler = { completion in
            completion(false)
        }
        
        // Act
        sut.isBluetoothEnabled { (isEnabled) in
            XCTAssertFalse(isEnabled)
            completionExpectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(mockOnboardingConsentManager.isBluetoothEnabledCallCount, 1)
    }
    
    func test_bluetoothSettingsDidComplete_shouldRouteToConsent() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        XCTAssertEqual(mockOnboardingConsentManager.getNextConsentStepCallCount, 0)
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 0)
        
        mockOnboardingRouter.routeToConsentWithIndexHandler = { index, animated in
            XCTAssertEqual(index, OnboardingConsentStep.Index.share.rawValue)
            XCTAssertTrue(animated)
            completionExpectation.fulfill()
        }
        
        mockOnboardingConsentManager.getNextConsentStepHandler = { step, skippedCurrentStep, completion in
            XCTAssertEqual(step, .bluetooth)
            completion(.share)
        }
        
        // Act
        sut.bluetoothSettingsDidComplete()
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 1)
        XCTAssertEqual(mockOnboardingConsentManager.getNextConsentStepCallCount, 1)
    }
    
    func test_bluetoothSettingsDidComplete_shouldCompleteOnboarding() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        XCTAssertEqual(mockOnboardingConsentManager.getNextConsentStepCallCount, 0)
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 0)
                        
        mockOnboardingConsentManager.getNextConsentStepHandler = { step, skippedCurrentStep, completion in
            XCTAssertEqual(step, .bluetooth)
            completion(nil)
        }
        
        mockOnboardingListener.didCompleteOnboardingHandler = {
            completionExpectation.fulfill()
        }
        
        // Act
        sut.bluetoothSettingsDidComplete()
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(mockOnboardingConsentManager.getNextConsentStepCallCount, 1)
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 1)
    }
    
    func test_helpRequestsEnableApp_shouldCompleteOnboarding() {
        // Arrange
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 0)
        XCTAssertEqual(mockOnboardingConsentManager.didCompleteConsentCallCount, 0)
        
        mockOnboardingConsentManager.askNotificationsAuthorizationHandler = { completion in
            completion()
        }
        
        mockOnboardingConsentManager.askEnableExposureNotificationsHandler = { completion in
            completion(.active)
        }
        
        mockOnboardingConsentManager.getNextConsentStepHandler = { currentStep, skippedCurrentStep, completion in
            completion(nil)
        }
        
        // Act
        sut.helpRequestsEnableApp()
        
        // Assert
        XCTAssertEqual(mockOnboardingConsentManager.didCompleteConsentCallCount, 1)
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 1)
    }
    
    func test_helpRequestsEnableApp_notAuthorized_shouldCompleteOnboarding() {
        // Arrange
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 0)
        XCTAssertEqual(mockOnboardingConsentManager.didCompleteConsentCallCount, 0)
        
        mockOnboardingConsentManager.askNotificationsAuthorizationHandler = { completion in
            completion()
        }
        
        mockOnboardingConsentManager.askEnableExposureNotificationsHandler = { completion in
            completion(.notAuthorized)
        }
        
        // Act
        sut.helpRequestsEnableApp()
        
        // Assert
        XCTAssertEqual(mockOnboardingConsentManager.didCompleteConsentCallCount, 1)
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 1)
    }
    
    func test_helpRequestsEnableApp_shouldRouteToConsent() {
        // Arrange
        XCTAssertEqual(mockOnboardingListener.didCompleteOnboardingCallCount, 0)
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 0)
        
        mockOnboardingConsentManager.askNotificationsAuthorizationHandler = { completion in
            completion()
        }
        
        mockOnboardingConsentManager.askEnableExposureNotificationsHandler = { completion in
            completion(.active)
        }
        
        mockOnboardingConsentManager.getNextConsentStepHandler = { step, skippedCurrentStep, completion in
            XCTAssertEqual(step, .en)
            completion(.share)
        }
        
        // Act
        sut.helpRequestsEnableApp()
        
        // Assert
        XCTAssertEqual(mockOnboardingConsentManager.didCompleteConsentCallCount, 1)
        XCTAssertEqual(mockOnboardingRouter.routeToConsentWithIndexCallCount, 1)
    }
    
    func test_displayShareApp_shouldCallRouter() {
        // Arrange
        XCTAssertEqual(mockOnboardingRouter.routeToShareAppCallCount, 0)
        
        // Act
        sut.displayShareApp()
        
        // Assert
        XCTAssertEqual(mockOnboardingRouter.routeToShareAppCallCount, 1)
    }
}

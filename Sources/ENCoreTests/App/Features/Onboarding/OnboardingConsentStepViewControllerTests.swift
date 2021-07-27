/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
import RxSwift
@testable import ENCore

class OnboardingConsentStepViewControllerTests: TestCase {
    
    private var mockOnboardingConsentManager: OnboardingConsentManagingMock!
    private var mockInterfaceOrientationStream: InterfaceOrientationStreamingMock!
    private var mockListener: OnboardingConsentListenerMock!
    
    override func setUpWithError() throws {
        mockOnboardingConsentManager = OnboardingConsentManagingMock()
        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockListener = OnboardingConsentListenerMock()
        
        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
    }
    
    func test_snapshot() {
        // Arrange
        let sut = buildSut(withStepIndex: .en)
        
        // Act
        snapshots(matching: sut)
    }
    
    private func buildSut(withStepIndex stepIndex: OnboardingConsentStep.Index) -> OnboardingConsentStepViewController {
        let step = OnboardingConsentStep(
            step: stepIndex,
            theme: theme,
            title: "Some Onboarding Step Title",
            content: "Some Onboarding Step Content",
            illustration: .image(.pleaseTurnOnBluetooth),
            primaryButtonTitle: .consentStep4PrimaryButton,
            secondaryButtonTitle: .consentStep4SecondaryButton,
            hasNavigationBarSkipButton: false
        )
        
        mockOnboardingConsentManager.getStepHandler = { _ in
            step
        }
        
        return OnboardingConsentStepViewController(onboardingConsentManager: mockOnboardingConsentManager,
                                                   listener: mockListener,
                                                   theme: theme,
                                                   index: 0,
                                                   interfaceOrientationStream: mockInterfaceOrientationStream)
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
import SnapshotTesting
@testable import ENCore

class OnboardingConsentSummaryStepsViewTests: TestCase {

    func test_snapshot_singleStep() {
        let steps = [
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep0, image: .privacyShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep1, image: .bluetoothShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep2, image: .bluetoothShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep4, image: .bluetoothShield),
            OnboardingConsentSummaryStep(theme: theme, title: .consentStep1Summary2, image: .lockShield),
            OnboardingConsentSummaryStep(theme: theme, title: .consentStep1Summary3, image: .lockShield),
            OnboardingConsentSummaryStep(theme: theme, title: .privacyAgreementStep3, image: .bellShield)
        ]
        let sut = OnboardingConsentSummaryStepsView(with: steps, theme: theme)
        
        assertSnapshot(matching:sut, as: .image())
    }
}

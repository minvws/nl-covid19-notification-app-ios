/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

protocol OnboardingConsentManaging {
    var onboardingConsentSteps: [OnboardingConsentStep] { get }
    
    func getStep(_ index: Int) -> OnboardingConsentStep?
    func getNextStepIndex(_ currentIndex: Int) -> Int?
}

final class OnboardingConsentManager: OnboardingConsentManaging {

    var onboardingConsentSteps: [OnboardingConsentStep] = []

    init() {

        onboardingConsentSteps.append(
            OnboardingConsentStep(
                title: Localized("consentStep1Title"),
                content: Localized("consentStep1Content"),
                image: nil,
                summarySteps: [
                    OnboardingConsentSummaryStep(
                        title: NSAttributedString(string: Localized("consentStep1Summary1")),
                        image: UIImage(named: "CheckmarkShield")
                    ),
                    OnboardingConsentSummaryStep(
                        title: NSAttributedString(string: Localized("consentStep1Summary2")),
                        image: UIImage(named: "CheckmarkShield")
                    ),
                    OnboardingConsentSummaryStep(
                        title: NSAttributedString(string: Localized("consentStep1Summary3")),
                        image: UIImage(named: "CheckmarkShield")
                    )
                ],
                primaryButtonTitle: Localized("consentPermissionsButton"),
                secondaryButtonTitle: Localized("consentExplanationButton")
            )
        )
    }

    func getStep(_ index: Int) -> OnboardingConsentStep? {
        if self.onboardingConsentSteps.count > index { return self.onboardingConsentSteps[index] }
        return nil
    }

    // TODO: Add EN, Bluetooth and other checks to return the correct index
    func getNextStepIndex(_ currentIndex: Int) -> Int? {
        let nextIndex = currentIndex + 1
        if self.onboardingConsentSteps.count > nextIndex { return nextIndex }
        return nil
    }
}

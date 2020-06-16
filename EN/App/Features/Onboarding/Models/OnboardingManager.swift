/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// @mockable
protocol OnboardingManaging {
    var onboardingSteps: [OnboardingStep] { get }
    
    func getStep(_ index: Int) -> OnboardingStep?
}

final class OnboardingManager: OnboardingManaging {

    var onboardingSteps: [OnboardingStep] = []

    init(theme: Theme) {

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localized("step1Title"),
                content: Localized("step1Content"),
                image: UIImage(named: "Step1") ?? UIImage(),
                buttonTitle: Localized("nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localized("step2Title"),
                content: Localized("step2Content"),
                image: UIImage(named: "Step2") ?? UIImage(),
                buttonTitle: Localized("nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localized("step3Title"),
                content: Localized("step3Content"),
                image: UIImage(named: "Step3") ?? UIImage(),
                buttonTitle: Localized("nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localized("step4Title"),
                content: Localized("step4Content"),
                image: UIImage(named: "Step4") ?? UIImage(),
                buttonTitle: Localized("nextButtonTitle"),
                isExample: true
            )
        )
    }

    func getStep(_ index: Int) -> OnboardingStep? {
        if self.onboardingSteps.count > index { return self.onboardingSteps[index] }
        return nil
    }
}

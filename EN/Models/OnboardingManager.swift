/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

class OnboardingManager {

    static let shared = OnboardingManager()

    var onboardingSteps: [OnboardingStep] = []

    init() {

        onboardingSteps.append(
            OnboardingStep(
                title: localized("step1Title"),
                content: localized("step1Content"),
                image: UIImage(named: "Step1") ?? UIImage(),
                buttonTitle: localized("nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                title: localized("step2Title"),
                content: localized("step2Content"),
                image: UIImage(named: "Step2") ?? UIImage(),
                buttonTitle: localized("nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                title: localized("step3Title"),
                content: localized("step3Content"),
                image: UIImage(named: "Step3") ?? UIImage(),
                buttonTitle: localized("nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                title: localized("step4Title"),
                content: localized("step4Content"),
                image: UIImage(named: "Step4") ?? UIImage(),
                buttonTitle: localized("nextButtonTitle"),
                isExample: true
            )
        )
    }

    deinit { }

    func getStep(_ index: Int) -> OnboardingStep? {
        if self.onboardingSteps.count > index { return self.onboardingSteps[index] }
        return nil
    }
}

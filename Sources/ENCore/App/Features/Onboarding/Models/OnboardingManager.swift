/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// @mockable
protocol OnboardingManaging {
    var onboardingSteps: [OnboardingStep] { get }

    func getStep(_ index: Int) -> OnboardingStep?
}

final class OnboardingManager: OnboardingManaging {

    let onboardingSteps: [OnboardingStep]

    // MARK: -

    init(theme: Theme) {
        self.onboardingSteps = [
            OnboardingStep(
                theme: theme,
                title: .step1Title,
                content: .step1Content,
                illustration: .image(named: "Step1"),
                buttonTitle: .nextButtonTitle,
                isExample: false
            ),
            OnboardingStep(
                theme: theme,
                title: .step2Title,
                content: .step2Content,
                illustration: .animation(named: "popup", repeatFromFrame: 94, defaultFrame: 121),
                buttonTitle: .nextButtonTitle,
                isExample: false
            ),
            OnboardingStep(
                theme: theme,
                title: .step3Title,
                content: .step3Content,
                illustration: .animation(named: "bluetooth", defaultFrame: 28),
                buttonTitle: .nextButtonTitle,
                isExample: false
            ),
            OnboardingStep(
                theme: theme,
                title: .step4Title,
                content: .step4Content,
                illustration: .animation(named: "ontheway", defaultFrame: 36),
                buttonTitle: .nextButtonTitle,
                isExample: true
            ),
            OnboardingStep(
                theme: theme,
                title: .step5Title,
                content: .step5Content,
                illustration: .animation(named: "train", repeatFromFrame: 51, defaultFrame: 93),
                buttonTitle: .nextButtonTitle,
                isExample: true
            )
        ]
    }

    func getStep(_ index: Int) -> OnboardingStep? {
        if self.onboardingSteps.count > index { return self.onboardingSteps[index] }
        return nil
    }
}

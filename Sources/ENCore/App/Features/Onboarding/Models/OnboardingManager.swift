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
                title: Localization.string(for: "step1Title"),
                content: Localization.string(for: "step1Content"),
                image: Image.named("Step1") ?? UIImage(),
                animationName: "ontheway",
                buttonTitle: Localization.string(for: "nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localization.string(for: "step2Title"),
                content: Localization.string(for: "step2Content"),
                image: Image.named("Step2") ?? UIImage(),
                animationName: "bluetooth",
                buttonTitle: Localization.string(for: "nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localization.string(for: "step3Title"),
                content: Localization.string(for: "step3Content"),
                image: Image.named("Step3") ?? UIImage(),
                animationName: "popup",
                buttonTitle: Localization.string(for: "nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localization.string(for: "step4Title"),
                content: Localization.string(for: "step4Content"),
                image: Image.named("Step4") ?? UIImage(),
                animationName: nil,
                buttonTitle: Localization.string(for: "nextButtonTitle"),
                isExample: true
            )
        )
    }

    func getStep(_ index: Int) -> OnboardingStep? {
        if self.onboardingSteps.count > index { return self.onboardingSteps[index] }
        return nil
    }
}

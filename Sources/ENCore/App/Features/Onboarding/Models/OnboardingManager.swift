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
                illustration: .animation(named: "ontheway"),
                buttonTitle: Localization.string(for: "nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localization.string(for: "step2Title"),
                content: Localization.string(for: "step2Content"),
                illustration: .animation(named: "popup", repeatFromFrame: 94),
                buttonTitle: Localization.string(for: "nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localization.string(for: "step3Title"),
                content: Localization.string(for: "step3Content"),
                illustration: .animation(named: "bluetooth"),
                buttonTitle: Localization.string(for: "nextButtonTitle"),
                isExample: false
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localization.string(for: "step4Title"),
                content: Localization.string(for: "step4Content"),
                illustration: .animation(named: "ontheway"),
                buttonTitle: Localization.string(for: "nextButtonTitle"),
                isExample: true
            )
        )

        onboardingSteps.append(
            OnboardingStep(
                theme: theme,
                title: Localization.string(for: "step5Title"),
                content: Localization.string(for: "step5Content"),
                illustration: .image(named: "Step5"),
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

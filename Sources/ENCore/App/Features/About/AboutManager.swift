/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// @mockable
protocol AboutManaging {
    var questionsSection: AboutSection { get }
    var aboutSection: AboutSection { get }
}

struct AboutSection {
    let title: String
    let questions: [HelpQuestion]
}

final class AboutManager: AboutManaging {
    let questionsSection: AboutSection
    let aboutSection: AboutSection

    init(theme: Theme) {
        questionsSection = AboutSection(title: .helpSubtitle, questions: [
            HelpQuestion(
                theme: theme,
                question: .helpFaqLocationTitle,
                answer: .helpFaqLocationDescription),
            HelpQuestion(
                theme: theme,
                question: .helpFaqAnonymousTitle,
                answer: .helpFaqAnonymousDescription1 + "\n\n" + .helpFaqAnonymousDescription2),
            HelpQuestion(
                theme: theme,
                question: .helpFaqNotificationTitle,
                answer: .helpFaqNotificationDescription),
            HelpQuestion(
                theme: theme,
                question: .helpFaqBluetoothTitle,
                answer: .helpFaqBluetoothDescription),
            HelpQuestion(
                theme: theme,
                question: .helpFaqPowerUsageTitle,
                answer: .helpFaqPowerUsageDescription)
        ])

        aboutSection = AboutSection(title: .moreInformationAboutTitle, questions: [
            HelpQuestion(
                theme: theme,
                question: .helpPrivacyPolicyTitle,
                answer: "",
                link: .helpPrivacyPolicyLink),
            HelpQuestion(
                theme: theme,
                question: .helpAccessibilityTitle,
                answer: "",
                link: .helpAccessibilityLink),
            HelpQuestion(
                theme: theme,
                question: .helpColofonTitle,
                answer: .helpColofonDescription)
        ])
    }
}

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
            HelpQuestion(theme: theme, question: .aboutFaqReason, answer: .aboutFaqReasonAnswer),
            HelpQuestion(theme: theme, question: .aboutFaqLocation, answer: .aboutFaqLocationAnswer),
            HelpQuestion(theme: theme, question: .aboutFaqAnonymous, answer: .aboutFaqAnonymousAnswer),
            HelpQuestion(theme: theme, question: .aboutFaqNotification, answer: .aboutFaqNotificationAnswer),
            HelpQuestion(theme: theme, question: .aboutFaqUploadKeys, answer: .aboutFaqUploadKeysAnswer),
            HelpQuestion(theme: theme, question: .aboutFaqBluetooth, answer: .aboutFaqBluetoothAnswer),
            HelpQuestion(theme: theme, question: .aboutFaqPowerUsage, answer: .aboutFaqPowerUsageAnswer),
            HelpQuestion(theme: theme, question: .aboutFaqDeletion, answer: .aboutFaqDeletionAnswer),
            HelpQuestion(theme: theme, question: .aboutFaqLocationProvision, answer: .aboutFaqLocationProvisionAnswer)
        ])

        aboutSection = AboutSection(title: .moreInformationAboutTitle, questions: [
            HelpQuestion(theme: theme, question: .helpPrivacyPolicyTitle, answer: "", link: .helpPrivacyPolicyLink),
            HelpQuestion(theme: theme, question: .helpAccessibilityTitle, answer: "", link: .helpAccessibilityLink),
            HelpQuestion(theme: theme, question: .helpColofonTitle, answer: "", link: .helpColofonLink)
        ])
    }
}

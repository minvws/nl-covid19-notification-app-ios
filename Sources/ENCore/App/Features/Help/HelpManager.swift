/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import UIKit

/// @mockable
protocol HelpManaging {
    var questions: [HelpQuestion] { get }
}

final class HelpManager: HelpManaging {

    let questions: [HelpQuestion]

    init(theme: Theme) {

        questions = [
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
                answer: .helpFaqPowerUsageDescription),
            HelpQuestion(
                theme: theme,
                question: .helpPrivacyPolicyTitle,
                answer: "",
                link: .helpPrivacyPolicyLink),
            HelpQuestion(
                theme: theme,
                question: .helpAccessibilityTitle,
                answer: "",
                link: .helpAccessibilityLink)
        ]
    }
}

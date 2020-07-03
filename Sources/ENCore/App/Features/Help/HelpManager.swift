/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
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
                question: Localization.string(for: "help.faq.location.title"),
                answer: Localization.string(for: "help.faq.location.description")),
            HelpQuestion(
                theme: theme,
                question: Localization.string(for: "help.faq.anonymous.title"),
                answer: Localization.string(for: "help.faq.anonymous.description_1") + "\n\n" + Localization.string(for: "help.faq.anonymous.description_2")),
            HelpQuestion(
                theme: theme,
                question: Localization.string(for: "help.faq.notification.title"),
                answer: Localization.string(for: "help.faq.notification.description")),
            HelpQuestion(
                theme: theme,
                question: Localization.string(for: "help.faq.bluetooth.title"),
                answer: Localization.string(for: "help.faq.bluetooth.description")),
            HelpQuestion(
                theme: theme,
                question: Localization.string(for: "help.faq.power_usage.title"),
                answer: Localization.string(for: "help.faq.power_usage.description"))
        ]
    }
}

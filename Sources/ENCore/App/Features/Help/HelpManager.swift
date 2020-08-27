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

    init() {
        let reason = HelpQuestion(question: .helpFaqReasonTitle, answer: .helpFaqReasonDescription)
        let location = HelpQuestion(question: .helpFaqLocationTitle, answer: .helpFaqLocationDescription)
        let anonymous = HelpQuestion(question: .helpFaqAnonymousTitle, answer: .helpFaqAnonymousDescription1 + "\n\n" + .helpFaqAnonymousDescription2)
        let notification = HelpQuestion(question: .helpFaqNotificationTitle, answer: .helpFaqNotificationDescription)
        let bluetooth = HelpQuestion(question: .helpFaqBluetoothTitle, answer: .helpFaqBluetoothDescription)
        let power = HelpQuestion(question: .helpFaqPowerUsageTitle, answer: .helpFaqPowerUsageDescription)

        questions = [
            reason.appending(linkedQuestions: [location, notification]),
            anonymous.appending(linkedQuestions: [notification, location]),
            location.appending(linkedQuestions: [bluetooth]),
            // TODO: Link new screen 'wat betekent het als je een melding krijgt'
            notification.appending(linkedQuestions: [ /* Add link to new screen */ bluetooth]),
            bluetooth.appending(linkedQuestions: [notification, anonymous]),
            power.appending(linkedQuestions: [location, reason])
        ]
    }
}

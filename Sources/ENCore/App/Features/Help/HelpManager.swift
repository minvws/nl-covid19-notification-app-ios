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
            HelpQuestion(question: .helpFaqReasonTitle, answer: .helpFaqReasonDescription),
            HelpQuestion(question: .helpFaqLocationTitle, answer: .helpFaqLocationDescription),
            HelpQuestion(question: .helpFaqAnonymousTitle, answer: .helpFaqAnonymousDescription1 + "\n\n" + .helpFaqAnonymousDescription2),
            HelpQuestion(question: .helpFaqNotificationTitle, answer: .helpFaqNotificationDescription),
            HelpQuestion(question: .helpFaqUploadKeysTitle, answer: .helpFaqUploadKeysDescription),
            HelpQuestion(question: .helpFaqBluetoothTitle, answer: .helpFaqBluetoothDescription),
            HelpQuestion(question: .helpFaqPowerUsageTitle, answer: .helpFaqPowerUsageDescription)
        ]
    }
}

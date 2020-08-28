/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

final class HelpQuestion {
    let question: String
    let answer: String
    var linkedEntries: [HelpDetailEntry] = []

    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }

    func appending(linkedEntries: [HelpDetailEntry]) -> HelpQuestion {
        self.linkedEntries = linkedEntries
        return self
    }
}

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
    let attributedTitle: NSAttributedString
    let attributedAnswer: NSAttributedString

    init(theme: Theme, question: String, answer: String) {

        self.question = question
        self.attributedTitle = .makeFromHtml(text: question, font: theme.fonts.largeTitle, textColor: theme.colors.gray)
        self.attributedAnswer = .makeFromHtml(text: answer, font: theme.fonts.body, textColor: theme.colors.gray)
    }
}

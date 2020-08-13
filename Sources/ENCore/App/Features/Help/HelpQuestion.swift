/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

enum RedirectType { case rateApp }

final class HelpQuestion {

    let question: String
    let attributedTitle: NSAttributedString
    let attributedAnswer: NSAttributedString?
    let link: String?
    let redirectType: RedirectType?

    init(theme: Theme, question: String, answer: String?, link: String? = nil, redirectType: RedirectType? = nil) {

        self.question = question

        self.attributedTitle = .makeFromHtml(text: question,
                                             font: theme.fonts.largeTitle,
                                             textColor: theme.colors.gray,
                                             textAlignment: Localization.isRTL ? .right : .left)
        if let answer = answer {
            self.attributedAnswer = .makeFromHtml(text: answer,
                                                  font: theme.fonts.body,
                                                  textColor: theme.colors.gray,
                                                  textAlignment: Localization.isRTL ? .right : .left)
        } else {
            self.attributedAnswer = nil
        }

        self.link = link
        self.redirectType = redirectType
    }
}

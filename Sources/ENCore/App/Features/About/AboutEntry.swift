/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum AboutEntry: HelpDetailEntry {
    case question(_ question: HelpQuestion)
    case link(title: String, link: String)
    case rate(title: String)

    var title: String {
        switch self {
        case let .question(question):
            return question.question
        case let .rate(title), let .link(title, _):
            return title
        }
    }

    var answer: String {
        switch self {
        case let .question(question):
            return question.answer
        default:
            return ""
        }
    }

    var linkedEntries: [HelpDetailEntry] {
        switch self {
        case let .question(question):
            return question.linkedEntries
        default:
            return []
        }
    }
}

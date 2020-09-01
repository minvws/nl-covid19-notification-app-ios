/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum AboutEntry: HelpDetailEntry, LinkedContent {
    case question(_ question: HelpQuestion)
    case link(title: String, link: String)
    case rate(title: String)
    case notificationExplanation(title: String, linkedContent: [LinkedContent])
    case appInformation(linkedContent: [LinkedContent])
    case technicalInformation(title: String, linkedContent: [LinkedContent])

    var title: String {
        switch self {
        case let .question(question):
            return question.question
        case let .rate(title), let .link(title, _), let .notificationExplanation(title, _), let .technicalInformation(title, _):
            return title
        default:
            return ""
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

    var linkedEntries: [LinkedContent] {
        switch self {
        case let .question(question):
            return question.linkedContent
        case let .notificationExplanation(_, linkedContent), let .appInformation(linkedContent), let .technicalInformation(_, linkedContent):
            return linkedContent
        default:
            return []
        }
    }
}

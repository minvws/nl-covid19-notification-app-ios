/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum AboutEntry {
    case question(title: String, answer: String)
    case link(title: String, link: String)
    case rate(title: String)

    func title() -> String {
        switch self {
        case let .question(title, _), let .rate(title), let .link(title, _):
            return title
        }
    }
}

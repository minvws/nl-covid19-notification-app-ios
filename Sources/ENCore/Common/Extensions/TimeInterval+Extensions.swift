/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension TimeInterval {
    static func minutes(_ minutes: Double) -> TimeInterval {
        return TimeInterval(minutes * 60)
    }

    static func hours(_ hours: Double) -> TimeInterval {
        return TimeInterval(hours * 3600)
    }
}

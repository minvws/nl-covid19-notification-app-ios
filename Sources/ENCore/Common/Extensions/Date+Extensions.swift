/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension Date {
    func isBefore(_ otherDate: Date) -> Bool {
        otherDate.timeIntervalSince(self) > 0
    }

    func isEqualOrGreaterThan(_ otherDate: Date) -> Bool {
        return !isBefore(otherDate)
    }
}

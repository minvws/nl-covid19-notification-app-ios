/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension TimeInterval {

    static func seconds(_ seconds: Double) -> TimeInterval {
        return TimeInterval(seconds)
    }

    static func minutes(_ minutes: Double) -> TimeInterval {
        return TimeInterval(minutes * 60)
    }

    static func hours(_ hours: Double) -> TimeInterval {
        return TimeInterval(hours * 3600)
    }

    static func days(_ days: Double) -> TimeInterval {
        return TimeInterval(hours(24) * days)
    }

    func roundedToUpperMinute() -> TimeInterval {
        let fullMinutes = Int(self / .minutes(1))
        let secondsWithinMinute = self.truncatingRemainder(dividingBy: .minutes(1))
        if secondsWithinMinute != 0, self >= 0 {
            return (Double(fullMinutes) * 60) + .minutes(1)
        } else {
            return self
        }
    }
}

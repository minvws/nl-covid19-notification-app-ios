/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

public extension Collection {
    subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension Date {

    func days(sinceDate: Date) -> Int? {
        return Calendar.current.dateComponents([.day], from: sinceDate, to: self).day
    }

    func hours(sinceDate: Date) -> Int? {
        return Calendar.current.dateComponents([.hour], from: sinceDate, to: self).hour
    }
}

/// Returns the current date. This global method should be used instead of constructing a Date. Unit tests will
/// provide a consistent date object to reduce falkiness.
public func currentDate() -> Date {
    #if DEBUG
        if let date = DateTimeTestingOverrides.overriddenCurrentDate {
            return date
        }
    #endif
    return Date()
}

public func animationsEnabled() -> Bool {
    #if DEBUG
        if let enabled = AnimationTestingOverrides.animationsEnabled {
            return enabled
        }
    #endif
    return true
}

#if DEBUG
    /// Overriden date and time related properties
    public struct DateTimeTestingOverrides {
        /// Overriden current date for testing
        public static var overriddenCurrentDate: Date?
    }

    /// Overrides animation
    public struct AnimationTestingOverrides {
        public static var animationsEnabled: Bool?
    }
#endif

public extension String {
    var capitalizedFirstLetterOnly: String {
        return prefix(1).capitalized + dropFirst()
    }
}

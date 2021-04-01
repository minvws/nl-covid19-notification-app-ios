/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

public extension Collection {
    subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension Date {

    func days(sinceDate: Date) -> Int? {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: sinceDate), to: calendar.startOfDay(for: self)).day
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
    return UIAccessibility.isReduceMotionEnabled ? false : true
}

public func webViewLoadingEnabled() -> Bool {
    #if DEBUG
        if let enabled = WebViewTestingOverrides.webViewLoadingEnabled {
            return enabled
        }
    #endif
    return true
}

public func localization() -> String? {
    #if DEBUG
        // Not needed but makes the compiler happy during Debug mode
        if let overriddenLocalization = LocalizationOverrides.overriddenLocalization {
            return overriddenLocalization
        }
    #endif
    return nil
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

    /// Overrides animation
    public struct WebViewTestingOverrides {
        public static var webViewLoadingEnabled: Bool?
    }

    public struct LocalizationOverrides {
        public static var overriddenLocalization: String?
        public static var overriddenCurrentLanguageIdentifier: String?
        public static var overriddenIsRTL: Bool?
    }
#endif

public extension String {
    var capitalizedFirstLetterOnly: String {
        return prefix(1).capitalized + dropFirst()
    }
}

public extension String {
    var asGGDkey: String {
        guard !self.contains("-") || self.count == 7 else {
            return self
        }

        var elements = Array(self)
        var formattedKey = "\(elements[0])"
        elements.remove(at: 0)

        stride(from: 0, to: elements.count, by: 2).forEach {
            formattedKey += String(elements[$0 ..< min($0 + 2, elements.count)])
            if $0 + 2 < elements.count {
                formattedKey += "-"
            }
        }
        return formattedKey
    }
}

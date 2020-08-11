/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Get the scaled font
func font(size: CGFloat, weight: UIFont.Weight, textStyle: UIFont.TextStyle) -> UIFont {
    let font = UIFont.systemFont(ofSize: size, weight: weight)
    let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
    return fontMetrics.scaledFont(for: font)
}

/// Get the Localized string for the current bundle.
func localizedString(for key: String, comment: String = "", _ arguments: [CVarArg] = []) -> String {
    let value = NSLocalizedString(key, comment: comment)
    guard value == key else {
        return String(format: value, arguments: arguments)
    }
    guard
        let path = Bundle.main.path(forResource: "Base", ofType: "lproj"),
        let bundle = Bundle(path: path) else {
        return String(format: value, arguments: arguments)
    }
    let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
    return String(format: localizedString, arguments: arguments)
}

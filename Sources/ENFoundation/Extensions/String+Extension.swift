/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

public extension String {
    func removingCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }

    func removingCharacters(from: String) -> String {
        return removingCharacters(from: CharacterSet(charactersIn: from))
    }

    /// Returns string suitable for accessibility (voice over). A space will be added between each character to force voice over to spell each character individually.
    var stringForSpelling: String {
        var s = ""

        // Separate all characters
        let chars = self.map { String($0) }

        // Append all characters one by one
        for char in chars {
            // If there is already a character, append separator before appending next character
            if s.count > 0 {
                s += ","
            }
            // Append next character
            s += char
        }

        return s
    }
}

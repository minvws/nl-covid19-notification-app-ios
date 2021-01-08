/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol RandomizerProtocol {
    func randomInt(in range: ClosedRange<Int>) -> Int
    func randomFloat(in range: Range<Float>) -> Float
}

class Randomizer: RandomizerProtocol {
    func randomInt(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range)
    }

    func randomFloat(in range: Range<Float>) -> Float {
        Float.random(in: range)
    }
}

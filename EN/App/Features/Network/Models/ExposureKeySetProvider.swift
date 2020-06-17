/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol ExposureKeySetProvider {
    /// Returns the next keySetUrl. Once processed successfully,
    /// call the completion with the result. Upon a successful result,
    /// the keySet will be removed from disk
    func next() -> (url: URL, completion: (_ success: Bool) -> ())
}

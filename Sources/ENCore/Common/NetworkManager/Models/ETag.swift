/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct ETagStore: Codable {
    static let key = CodableStorageKey<ETagStore>(name: "etags", storeType: .insecure(volatile: false, maximumAge: nil))
    var etags = [String: String]()
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct ManifestKey: StoreKey {
    var asString: String = "manifest"
    var storeType: StoreType = .insecure(volatile: true, maximumAge: 60 * 60 * 4)
}

struct Manifest: Codable {

    static let key = ManifestKey()
    let exposureKeySets: [String]
    let resourceBundle, riskCalculationParameters, appConfig: String
}

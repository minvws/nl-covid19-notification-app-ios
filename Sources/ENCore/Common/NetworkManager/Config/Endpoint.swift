/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct Path {
    let components: [String]

    init(components: String...) {
        self.components = Array(components)
    }
}

struct Endpoint {

    // MARK: - CDN

    static let manifest = Path(components: "cdn", "v1", "manifest")
    static let exposureKeySet = Path(components: "cdn", "v1", "exposurekeyset")
    static let riskCalculationParameters = Path(components: "cdn", "riskcalculationparameters")

    static func appConfig(identifier: String) -> Path { Path(components: "cdn", "v1", "appconfig", identifier) }

    // MARK: - API

    static let register = Path(components: "v1", "register")
    static let postKeys = Path(components: "v1", "postkeys")
    static let stopKeys = Path(components: "v1", "stopkeys")
}

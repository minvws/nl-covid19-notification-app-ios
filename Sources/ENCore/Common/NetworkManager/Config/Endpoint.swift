/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct Path {
    let firstParameter: String
    let lastParameter: String
}

struct Endpoint {

    // MARK: - CDN

    static let manifest = Path(firstParameter: "cdn", lastParameter: "manifest")
    static let exposureKeySet = Path(firstParameter: "cdn", lastParameter: "exposurekeyset")
    static let riskCalculationParameters = Path(firstParameter: "cdn", lastParameter: "riskcalculationparameters")
    static let appConfig = Path(firstParameter: "cdn", lastParameter: "appconfig")

    // MARK: - API

    static let register = Path(firstParameter: "MobileAppApi", lastParameter: "register")
    static let postKeys = Path(firstParameter: "MobileAppApi", lastParameter: "postkeys")
    static let stopKeys = Path(firstParameter: "MobileAppApi", lastParameter: "stopkeys")
}

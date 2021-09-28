/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct Endpoint {

    let version: String?
    let pathComponents: [String]

    /// Initialize endpoint definition
    /// - Parameters:
    ///   - version: specific version of the endpoint that should be used (Configuration's `path` component will be used as a prefix if this is nil)
    ///   - components: other path components for the endpoint
    init(version: String? = nil, components: String...) {
        self.version = version
        self.pathComponents = Array(components)
    }

    // MARK: - CDN

    static let manifest = Endpoint(components: "manifest")

    static func appConfig(identifier: String) -> Endpoint { Endpoint(components: "appconfig", identifier) }
    static func exposureKeySet(identifier: String) -> Endpoint { Endpoint(components: "exposurekeyset", identifier) }
    static func riskCalculationParameters(identifier: String) -> Endpoint { Endpoint(components: "riskcalculationparameters", identifier) }
    static func treatmentPerspective(identifier: String) -> Endpoint { Endpoint(components: "resourcebundle", identifier) }

    // MARK: - API

    static let register = Endpoint(version: "v2", components: "register")
    static let postKeys = Endpoint(components: "postkeys")
    static let stopKeys = Endpoint(components: "stopkeys")
}

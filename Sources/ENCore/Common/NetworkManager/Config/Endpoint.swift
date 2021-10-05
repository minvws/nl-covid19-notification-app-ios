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

    static func manifest(version: String? = nil) -> Endpoint { Endpoint(version: version, components: "manifest") }

    static func appConfig(version: String? = nil, identifier: String) -> Endpoint { Endpoint(version: version, components: "appconfig", identifier) }
    static func exposureKeySet(version: String? = nil, identifier: String) -> Endpoint { Endpoint(version: version, components: "exposurekeyset", identifier) }
    static func riskCalculationParameters(version: String? = nil, identifier: String) -> Endpoint { Endpoint(version: version, components: "riskcalculationparameters", identifier) }
    static func treatmentPerspective(version: String? = nil, identifier: String) -> Endpoint { Endpoint(version: version, components: "resourcebundle", identifier) }

    // MARK: - API

    static let register = Endpoint(version: "v2", components: "register")
    static let postKeys = Endpoint(components: "postkeys")
    static let stopKeys = Endpoint(components: "stopkeys")
}

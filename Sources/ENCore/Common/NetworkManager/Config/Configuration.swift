/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct NetworkConfiguration {
    struct EndpointConfiguration {
        let scheme: String
        let host: String
        let port: Int?
        let path: [String]
        let sslFingerprints: [Certificate.Fingerprint]? // SSL pinning certificate, nil = no pinning
        let tokenParams: [String: String]
    }

    let name: String
    let api: EndpointConfiguration
    let cdn: EndpointConfiguration

    func sslFingerprints(forHost host: String) -> [Certificate.Fingerprint]? {
        if api.host == host { return api.sslFingerprints }
        if cdn.host == host { return cdn.sslFingerprints }

        return nil
    }

    static let development = NetworkConfiguration(
        name: "Development",
        api: .init(
            scheme: "http",
            host: "localhost",
            port: 5004,
            path: ["v01"],
            sslFingerprints: nil,
            tokenParams: [:]
        ),
        cdn: .init(
            scheme: "http",
            host: "localhost",
            port: 5004,
            path: ["v01"],
            sslFingerprints: nil,
            tokenParams: [:]
        )
    )

    static let test = NetworkConfiguration(
        name: "Test",
        api: .init(
            scheme: "https",
            host: "test.coronamelder-api.nl",
            port: nil,
            path: ["v1"],
            sslFingerprints: [Certificate.SSL.apiFingerprint, Certificate.SSL.apiV2Fingerprint],
            tokenParams: [:]
        ),
        cdn: .init(
            scheme: "https",
            host: "test.coronamelder-dist.nl",
            port: nil,
            path: ["v3"],
            sslFingerprints: [Certificate.SSL.cdnFingerprint, Certificate.SSL.cdnV2V3Fingerprint],
            tokenParams: [:]
        )
    )

    static let acceptance = NetworkConfiguration(
        name: "ACC",
        api: .init(
            scheme: "https",
            host: "acceptatie.coronamelder-api.nl",
            port: nil,
            path: ["v1"],
            sslFingerprints: [Certificate.SSL.apiFingerprint, Certificate.SSL.apiV2Fingerprint],
            tokenParams: [:]
        ),
        cdn: .init(
            scheme: "https",
            host: "acceptatie.coronamelder-dist.nl",
            port: nil,
            path: ["v3"],
            sslFingerprints: [Certificate.SSL.cdnFingerprint, Certificate.SSL.cdnV2V3Fingerprint],
            tokenParams: [:]
        )
    )

    static let production = NetworkConfiguration(
        name: "Production",
        api: .init(
            scheme: "https",
            host: "coronamelder-api.nl",
            port: nil,
            path: ["v1"],
            sslFingerprints: [Certificate.SSL.apiFingerprint, Certificate.SSL.apiV2Fingerprint],
            tokenParams: [:]
        ),
        cdn: .init(
            scheme: "https",
            host: "productie.coronamelder-dist.nl",
            port: nil,
            path: ["v3"],
            sslFingerprints: [Certificate.SSL.cdnFingerprint, Certificate.SSL.cdnV2V3Fingerprint],
            tokenParams: [:]
        )
    )

    var manifestUrl: URL? {
        return self.combine(path: Endpoint.manifest, fromCdn: true, params: cdn.tokenParams)
    }

    func exposureKeySetUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.exposureKeySet(identifier: identifier), fromCdn: true, params: cdn.tokenParams)
    }

    func riskCalculationParametersUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.riskCalculationParameters(identifier: identifier), fromCdn: true, params: cdn.tokenParams)
    }

    func appConfigUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.appConfig(identifier: identifier), fromCdn: true, params: cdn.tokenParams)
    }

    var registerUrl: URL? {
        return self.combine(path: Endpoint.register, fromCdn: false)
    }

    func postKeysUrl(signature: String) -> URL? {
        return self.combine(path: Endpoint.postKeys, fromCdn: false, params: ["sig": signature])
    }

    func stopKeysUrl(signature: String) -> URL? {
        return self.combine(path: Endpoint.stopKeys, fromCdn: false, params: ["sig": signature])
    }

    func getTreatmentPerspectiveUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.treatmentPerspective(identifier: identifier), fromCdn: true, params: cdn.tokenParams)
    }

    private func combine(path: Path, fromCdn: Bool, params: [String: String] = [:]) -> URL? {
        let config = fromCdn ? cdn : api

        var urlComponents = URLComponents()
        urlComponents.scheme = config.scheme
        urlComponents.host = config.host
        urlComponents.port = config.port
        urlComponents.path = "/" + (config.path + path.components).joined(separator: "/")

        if !params.isEmpty {
            urlComponents.percentEncodedQueryItems = params.compactMap { parameter in
                guard let name = parameter.key.addingPercentEncoding(withAllowedCharacters: urlQueryEncodedCharacterSet),
                    let value = parameter.value.addingPercentEncoding(withAllowedCharacters: urlQueryEncodedCharacterSet) else {
                    return nil
                }

                return URLQueryItem(name: name, value: value)
            }
        }

        return urlComponents.url
    }

    private var urlQueryEncodedCharacterSet: CharacterSet = {
        // WARNING: Do not remove this code, this will break signature validation on the backend.
        // specify characters which are allowed to be unespaced in the queryString, note the `inverted`
        let characterSet = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] ").inverted
        return characterSet
    }()
}

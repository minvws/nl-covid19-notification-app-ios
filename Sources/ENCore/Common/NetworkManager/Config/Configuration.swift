/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct NetworkConfiguration {

    let name: String
    let scheme: String
    let host: String
    let port: Int?
    let path: [String]

    static let development = NetworkConfiguration(
        name: "Development",
        scheme: "http",
        host: "10.0.0.133",
        port: 5004,
        path: ["v1"]
    )

    static let production = NetworkConfiguration(
        name: "Production",
        scheme: "https",
        host: "mss-standalone-acc.azurewebsites.net",
        port: nil,
        path: []
    )

    var manifestUrl: URL? {
        return self.combine(path: Endpoint.manifest)
    }

    func exposureKeySetUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.exposureKeySet, params: ["": identifier])
    }

    func riskCalculationParametersUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.riskCalculationParameters, params: ["": identifier])
    }

    func appConfigUrl(identifier: String) -> URL? {
        return self.combine(path: Endpoint.appConfig(identifier: identifier))
    }

    var registerUrl: URL? {
        return self.combine(path: Endpoint.register)
    }

    func postKeysUrl(signature: String) -> URL? {
        return self.combine(path: Endpoint.postKeys, params: ["sig": signature])
    }

    var stopKeysUrl: URL? {
        return self.combine(path: Endpoint.stopKeys)
    }

    private func combine(path: Path, params: [String: String] = [:]) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.port = port
        urlComponents.path = "/" + (self.path + path.components).joined(separator: "/")

        if params.count > 0 {
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
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove("+")

        return characterSet
    }()
}

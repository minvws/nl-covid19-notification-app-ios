/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct NetworkConfiguration {

    let url: String
    let path: String
    let contentType: ContentType

    static let development = NetworkConfiguration(
        url: "http://localhost:5004",
        path: "cdn/v1",
        contentType: .json
    )

    static let production = NetworkConfiguration(
        url: "https://www.rijksoverheid.nl/prod/",
        path: "api",
        contentType: .zip
    )

    var manifestUrl: URL {
        return self.combine(endpoint: Endpoint.manifest)
    }

    func exposureKeySetUrl(param: String) -> URL {
        return self.combine(endpoint: Endpoint.exposureKeySet, params: [param])
    }

    func riskCalculationParametersUrl(param: String) -> URL {
        return self.combine(endpoint: Endpoint.riskCalculationParameters, params: [param])
    }

    func appConfigUrl(param: String) -> URL {
        return self.combine(endpoint: Endpoint.riskCalculationParameters, params: [param])
    }

    var registerUrl: URL {
        return self.combine(endpoint: Endpoint.register)
    }

    var labConfirmUrl: URL {
        return self.combine(endpoint: Endpoint.labConfirm)
    }

    var postKeysUrl: URL {
        return self.combine(endpoint: Endpoint.postKeys)
    }

    var stopKeysUrl: URL {
        return self.combine(endpoint: Endpoint.stopKeys)
    }

    private func combine(endpoint: Endpoint, params: [String] = []) -> URL {
        let urlParts = [url, path, endpoint.rawValue] + params
        let endpoint: URL? = URL(string: urlParts.joined(separator: "/"))
        guard let url = endpoint else {
            fatalError("incorrect url")
        }
        print(url)
        return url
    }

    func getLocalUrl(name: String) -> URL {
        guard let url = Bundle.main.url(forAuxiliaryExecutable: name) else {
            fatalError("Local file not found")
        }
        return url
    }
}

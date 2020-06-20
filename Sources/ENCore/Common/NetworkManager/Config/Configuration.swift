/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct NetworkConfiguration {

    let url: String
    let version: String
    let contentType: ContentType

    static let development = NetworkConfiguration(
        url: "http://10.0.0.133:5004",
        version: "v1",
        contentType: .json
    )

    static let production = NetworkConfiguration(
        url: "https://api-ota.alleensamenmelden.nl/mss-acc",
        version: "v1",
        contentType: .zip
    )

    var manifestUrl: URL {
        return self.combine(path: Endpoint.manifest)
    }

    func exposureKeySetUrl(param: String) -> URL {
        return self.combine(path: Endpoint.exposureKeySet, params: [param])
    }

    func riskCalculationParametersUrl(param: String) -> URL {
        return self.combine(path: Endpoint.riskCalculationParameters, params: [param])
    }

    func appConfigUrl(param: String) -> URL {
        return self.combine(path: Endpoint.riskCalculationParameters, params: [param])
    }

    var registerUrl: URL {
        return self.combine(path: Endpoint.register)
    }

    var postKeysUrl: URL {
        return self.combine(path: Endpoint.postKeys)
    }

    var stopKeysUrl: URL {
        return self.combine(path: Endpoint.stopKeys)
    }

    private func combine(path: Path, params: [String] = []) -> URL {
        let urlParts = [url, version] + path.components + params
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

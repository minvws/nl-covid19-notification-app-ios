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
    let mock: Bool

    static let development = NetworkConfiguration(
        url: "http://localhost:5004",
        path: "MobileAppApi/v1",
        mock: false
    )

    static let production = NetworkConfiguration(
        url: "https://www.rijksoverheid.nl/prod/",
        path: "api",
        mock: false
    )

    var manifestUrl: URL {
        if mock {
            return self.getLocalUrl(name: "manifest.json")
        } else {
            return self.combine(endpoint: Endpoint.manifest)
        }
    }

    func exposureKeySetUrl(param: String) -> URL {
        if mock {
            return self.getLocalUrl(name: param)
        } else {
            return self.combine(endpoint: Endpoint.exposureKeySet, params: [param])
        }
    }

    func riskCalculationParametersUrl(param: String) -> URL {
        if mock {
            return self.getLocalUrl(name: "riskcalculationparameters.json")
        } else {
            return self.combine(endpoint: Endpoint.riskCalculationParameters, params: [param])
        }
    }

    func appConfigUrl(param: String) -> URL {
        if mock {
            return self.getLocalUrl(name: "appconfig.json")
        } else {
            return self.combine(endpoint: Endpoint.riskCalculationParameters, params: [param])
        }
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

/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

enum Endpoint: String {
    
    // MARK: GET
    case manifest = "manifest.json"
    case exposureKeySet = "exposurekeyset"
    case resourceBundle = "resourcebundle"
    case riskCalculationParameters = "riskcalculationparameters"
    case appConfig = "appconfig"
    
    // MARK: POST
    case register = "register"
    case labConfirm = "labconfirm"
    case postKeys = "postkeys"
    case stopKeys = "stopkeys"
    
}

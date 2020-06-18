/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import ZIPFoundation
enum UnzipNetworkResponseError: Error {
    case placeholder
}

/// @mockable
protocol UnzipNetworkResponseHandlerControlling {
    func unzip(_ data:Data)
}

final class UnzipNetworkResponseHandler : UnzipNetworkResponseHandlerControlling {
    func unzip(_ data: Data) {
        
        
    }
}

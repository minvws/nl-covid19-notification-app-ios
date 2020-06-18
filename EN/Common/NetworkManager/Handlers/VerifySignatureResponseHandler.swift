/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

enum VerifySignatureError: Error {
    case placeholder
}

/// @mockable
protocol VerifySignatureResponseHandlerControlling {
    func verify(_ data:Data, signature:String) throws -> Bool
}

final class VerifySignatureResponseHandler : VerifySignatureResponseHandlerControlling {
    func verify(_ data: Data, signature: String) throws -> Bool {
        return true
    }
    
    
}

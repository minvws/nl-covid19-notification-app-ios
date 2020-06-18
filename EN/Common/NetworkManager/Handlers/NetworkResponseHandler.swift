/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

enum NetworkResponseError: Error {
    case placeholder
    case unzipError(UnzipNetworkResponseError)
    case signatureError(VerifySignatureError)
}

/// @mockable
protocol NetworkResponseHandlerControlling {
    
    
    /// Should handle network response
    /// - Parameters:
    ///   - returnType: Response type of the object
    ///   - data: input data
    ///   - response: response from server
    ///   - error: error
    func handle<T>(_ returnType: T.Type, data: Data?, response: URLResponse?, error: Error?) throws -> T where T : Decodable
}

final class NetworkResponseHandler : NetworkResponseHandlerControlling {
    
    // handlers
    let verifySignatureHandler:VerifySignatureResponseHandler
    let unzipNetworkResponseHandler:UnzipNetworkResponseHandler
    
    init(verifySignatureHandler:VerifySignatureResponseHandler = VerifySignatureResponseHandler(),
         unzipNetworkResponseHandler:UnzipNetworkResponseHandler = UnzipNetworkResponseHandler()) {
        self.verifySignatureHandler = verifySignatureHandler
        self.unzipNetworkResponseHandler = unzipNetworkResponseHandler
    }
    
    func handle<T>(_ returnType: T.Type, data: Data?, response: URLResponse?, error: Error?) throws -> T where T : Decodable {
        throw NetworkResponseError.unzipError(.placeholder)
    }
    
    
}

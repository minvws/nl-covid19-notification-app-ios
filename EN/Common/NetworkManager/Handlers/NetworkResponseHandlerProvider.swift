/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

enum NetworkResponseError: Error {
    case placeholder
    case emptyUrl
    case fileNotFound
    case unzipError(UnzipNetworkResponseError)
    case signatureError(VerifySignatureError)
}

struct HandlerResult {
    let Object:Codable?
    let status:Bool
}

/// @mockable
protocol NetworkResponseHandling {}

final class NetworkResponseHandlerProvider {
   
    
    
    // handlers
    let verifySignatureHandler:VerifySignatureResponseHandler
    let unzipNetworkResponseHandler:UnzipNetworkResponseHandler
    
    init(verifySignatureHandler:VerifySignatureResponseHandler = VerifySignatureResponseHandler(),
         unzipNetworkResponseHandler:UnzipNetworkResponseHandler = UnzipNetworkResponseHandler()) {
        self.verifySignatureHandler = verifySignatureHandler
        self.unzipNetworkResponseHandler = unzipNetworkResponseHandler
    }
    
    
    func handleReturnData(url: URL?, response: URLResponse?, error: Error?) throws -> Data  {
        
        let files = try self.handleReturnUrls(url: url, response: response, error: error)
        let filtered = files.filter( { $0.pathExtension == "bin" } )
        
        guard let binUrl = filtered.first else {
             throw NetworkResponseError.fileNotFound
        }
        
        let data = try Data(contentsOf: binUrl)
        return data
    }
    
    func handleReturnUrls(url: URL?, response: URLResponse?, error: Error?) throws -> [URL]  {
        
        // handle errors
        if let error = error {
            throw error
        }
        
        guard let url = url else {
            throw NetworkResponseError.emptyUrl
        }
        
        // extract files
        let urls = try self.unzipNetworkResponseHandler.handle(url: url)
        if !self.verifySignatureHandler.handle(urls: urls) {
            throw NetworkResponseError.signatureError(.cantVerify)
        }
    
        return urls
    }
}

/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

enum NetworkResponseError: Error {
    case error
    case badRequest
    case serverError
}

final class NetworkResponseProvider : NetworkResponseProviderHandling {
   
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
             throw NetworkResponseError.error
        }
        
        let data = try Data(contentsOf: binUrl)
        return data
    }
    
    func handleReturnUrls(url: URL?, response: URLResponse?, error: Error?) throws -> [URL]  {
        
        // handle errors
        if let error = error {
            throw error
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            
            switch httpResponse.statusCode {
            case 400...499:
                throw NetworkResponseError.badRequest
            case 500...599:
                throw NetworkResponseError.serverError
            default:
                // continue
                break;
            }
        }
        
        guard let url = url else {
            throw NetworkResponseError.error
        }
        
        // extract files
        let urls = try self.unzipNetworkResponseHandler.handle(url: url)
        if !self.verifySignatureHandler.handle(urls: urls) {
            throw NetworkResponseError.error
        }
    
        return urls
    }
}

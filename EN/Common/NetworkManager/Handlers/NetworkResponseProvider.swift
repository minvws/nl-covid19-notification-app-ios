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


enum ContentType: String {
    case zip = "application/zip"
    case json = "application/json"
}

final class NetworkResponseProvider : NetworkResponseProviderHandling {
   
    
    // handlers
    let verifySignatureHandler:VerifySignatureResponseHandler
    let fileNetworkResponseHandler:FileNetworkResponseHandler
    
    init(verifySignatureHandler:VerifySignatureResponseHandler = VerifySignatureResponseHandler(),
         fileNetworkResponseHandler:FileNetworkResponseHandler = FileNetworkResponseHandler()) {
        self.verifySignatureHandler = verifySignatureHandler
        self.fileNetworkResponseHandler = fileNetworkResponseHandler
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
        
        // http response should always be available, local url aswell and content type needs to be set
        guard
            let httpResponse = response as? HTTPURLResponse,
            let url = url,
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
        else {
            throw NetworkResponseError.error
        }
        
        switch httpResponse.statusCode {
        case 400...499:
            throw NetworkResponseError.badRequest
        case 500...599:
            throw NetworkResponseError.serverError
        default: break
        }
        
        guard let type = ContentType.init(rawValue: contentType) else {
            throw NetworkResponseError.error
        }
        
        
        // extract files if necessary
        let urls = try self.fileNetworkResponseHandler.handle(url: url, type: type)
        if !self.verifySignatureHandler.handle(urls: urls) {
            throw NetworkResponseError.error
        }
    
        return urls
    }
}

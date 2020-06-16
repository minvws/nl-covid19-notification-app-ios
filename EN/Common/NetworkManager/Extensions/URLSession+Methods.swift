/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// mockable
protocol URLSessionManagable {
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
    
    func get(_ url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
    func download(_ url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void)
    func post(_ url: URL, object:Encodable, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

extension URLSession : URLSessionManagable {
    
    func get(_ url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = URLRequest(url: url)
        dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    func download(_ url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) {
        let request = URLRequest(url: url)
        downloadTask(with: request, completionHandler: completionHandler).resume()
    }
    
    func post(_ url: URL, object:Encodable, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        do {
            let jsonData = try JSONEncoder().encode(AnyEncodable(object))
            request.httpBody = jsonData
            dataTask(with: request, completionHandler: completionHandler).resume()
        } catch {
            completionHandler(nil, nil, error)
        }
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// mockable
protocol URLSessionManagable {

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionDataTask
    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> ()) -> URLSessionDownloadTask

    func get(_ url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> ())
    func download(_ url: URL, contentType:ContentType, completionHandler: @escaping (URL?, URLResponse?, Error?) -> ())

    func post(_ url: URL, object: Encodable, completionHandler: @escaping (Data?, URLResponse?, Error?) -> ())
}

extension URLSession: URLSessionManagable {

    func get(_ url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) {
        let request = URLRequest(url: url)
        dataTask(with: request, completionHandler: completionHandler).resume()
    }

    func download(_ url: URL, contentType:ContentType, completionHandler: @escaping (URL?, URLResponse?, Error?) -> ()) {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = ["Accept": contentType.rawValue]
        downloadTask(with: request, completionHandler: completionHandler).resume()
    }

    func post(_ url: URL,
              object: Encodable,
              completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) {
        var request = URLRequest(url: url)

        //request.allHTTPHeaderFields = defaultHeaders
        request.httpMethod = HTTPMethod.POST.rawValue

        do {
            let jsonData = try JSONEncoder().encode(AnyEncodable(object))
            request.httpBody = jsonData
            dataTask(with: request, completionHandler: completionHandler).resume()
        } catch {
            completionHandler(nil, nil, error)
        }
    }

    // TODO: Make this middleware
    private var defaultHeaders: [String: String] {
        return [
            "Content-Type": "application/json",
            "Accept": "application/zip"
        ]
    }
}

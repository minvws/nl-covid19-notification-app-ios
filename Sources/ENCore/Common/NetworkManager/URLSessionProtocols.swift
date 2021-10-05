/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

/// @mockable
protocol URLSessionTaskProtocol {
    var originalRequest: URLRequest? { get }
}

extension URLSessionTask: URLSessionTaskProtocol {}

/// @mockable(history:resumableDataTask=true)
protocol URLSessionProtocol {
    func resumableDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionDataTaskProtocol
    func getAllURLSessionTasks(completionHandler: @escaping ([URLSessionTaskProtocol]) -> ())
    func urlSessionDownloadTask(with request: URLRequest) -> URLSessionDownloadTaskProtocol
}

/// @mockable
protocol URLSessionDelegateProtocol: AnyObject {}

extension URLSession: URLSessionProtocol {
    func resumableDataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler)
    }

    func urlSessionDownloadTask(with request: URLRequest) -> URLSessionDownloadTaskProtocol {
        return downloadTask(with: request)
    }

    func getAllURLSessionTasks(completionHandler: @escaping ([URLSessionTaskProtocol]) -> ()) {
        getAllTasks(completionHandler: completionHandler)
    }
}

/// @mockable
protocol URLSessionDownloadTaskProtocol {
    var countOfBytesClientExpectsToSend: Int64 { get set }
    var countOfBytesClientExpectsToReceive: Int64 { get set }
    var originalRequest: URLRequest? { get }
    func resume()
}

extension URLSessionDownloadTask: URLSessionDownloadTaskProtocol {}

/// @mockable
protocol URLResponseProtocol {
    var contentType: String? { get }
}

extension URLResponse: URLResponseProtocol {
    var contentType: String? {
        if let response = self as? HTTPURLResponse {
            return response.allHeaderFields[HTTPHeaderKey.contentType.rawValue] as? String
        }

        return nil
    }
}

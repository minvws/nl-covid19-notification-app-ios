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

/// @mockable
protocol URLSessionProtocol {
    func resumableDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionDataTaskProtocol
    func getAllURLSessionTasks(completionHandler: @escaping ([URLSessionTaskProtocol]) -> Void)
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
    
    func getAllURLSessionTasks(completionHandler: @escaping ([URLSessionTaskProtocol]) -> Void) {
        getAllTasks(completionHandler: completionHandler)
    }
}

/// @mockable(history:build = true)
protocol URLSessionBuilding {
    func build(configuration: URLSessionConfiguration, delegate: URLSessionDelegateProtocol?, delegateQueue queue: OperationQueue?) -> URLSessionProtocol?
}

class URLSessionBuilder: URLSessionBuilding {
    func build(configuration: URLSessionConfiguration, delegate: URLSessionDelegateProtocol?, delegateQueue queue: OperationQueue?) -> URLSessionProtocol?  {
        
        guard let delegate = delegate as? URLSessionDelegate else {
            return nil
        }
        
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
    }
}

/// @mockable
protocol URLSessionDownloadTaskProtocol {
    var countOfBytesClientExpectsToSend: Int64 { get set }
    var countOfBytesClientExpectsToReceive: Int64 { get set }
    var originalRequest: URLRequest? { get }
    func resume()
}

extension URLSessionDownloadTask: URLSessionDownloadTaskProtocol { }

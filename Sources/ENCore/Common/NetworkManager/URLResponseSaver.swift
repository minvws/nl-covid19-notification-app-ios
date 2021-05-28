/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import RxSwift
import Foundation
import UIKit
import ENFoundation

/// @mockable(history:responseToLocalUrl=true)
protocol URLResponseSaving {
    func responseToLocalUrl(for response: URLResponseProtocol, url: URL, backgroundThreadIfPossible: Bool) -> Single<URL>
    func responseToLocalUrl(for response: URLResponseProtocol, url: URL) -> Single<URL>
}

final class URLResponseSaver: URLResponseSaving, Logging {

    private let responseHandlerProvider: NetworkResponseHandlerProvider
    private let concurrentUtilityScheduler = ConcurrentDispatchQueueScheduler(qos: .utility)
    
    init(responseHandlerProvider: NetworkResponseHandlerProvider) {
        self.responseHandlerProvider = responseHandlerProvider
    }
    
    func responseToLocalUrl(for response: URLResponseProtocol, url: URL) -> Single<URL> {
        responseToLocalUrl(for: response, url: url, backgroundThreadIfPossible: false)
    }

    func responseToLocalUrl(for response: URLResponseProtocol, url: URL, backgroundThreadIfPossible: Bool) -> Single<URL> {
        var localUrl = Single<URL>.just(url)

        if backgroundThreadIfPossible, UIApplication.shared.applicationState != .background {
            localUrl = localUrl
                .observe(on: concurrentUtilityScheduler)
        }

        // unzip
        let unzipResponseHandler = responseHandlerProvider.unzipNetworkResponseHandler
        if unzipResponseHandler.isApplicable(for: response, input: url) {
            localUrl = localUrl
                .flatMap { localUrl in unzipResponseHandler.process(response: response, input: localUrl) }
        }

        // verify signature
        let verifySignatureResponseHandler = responseHandlerProvider.verifySignatureResponseHandler
        if verifySignatureResponseHandler.isApplicable(for: response, input: url) {
            localUrl = localUrl
                .flatMap { localUrl in verifySignatureResponseHandler.process(response: response, input: localUrl) }
        }

        return localUrl
    }
}

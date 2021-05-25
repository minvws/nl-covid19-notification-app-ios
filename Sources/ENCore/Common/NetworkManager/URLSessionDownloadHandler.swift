/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift
import ENFoundation

/// @mockable
protocol URLSessionDownloadHandling {
    func processDownload(urlSessionIdentifier: URLSessionIdentifier, response: URLResponseProtocol, originalURL: URL, downloadLocation: URL)
}

class URLSessionDownloadHandler: URLSessionDownloadHandling {
    
    private let urlResponseSaver: URLResponseSaving
    private let keySetDownloadProcessor: KeySetDownloadProcessing
    private let disposeBag = DisposeBag()
    
    init(urlResponseSaver: URLResponseSaving,
         keySetDownloadProcessor: KeySetDownloadProcessing) {
        self.urlResponseSaver = urlResponseSaver
        self.keySetDownloadProcessor = keySetDownloadProcessor
    }
    
    func processDownload(urlSessionIdentifier: URLSessionIdentifier, response: URLResponseProtocol, originalURL: URL, downloadLocation: URL) {
        switch urlSessionIdentifier {
        case .keysetURLSession:
            guard let keySetIdentifier = originalURL.pathComponents.last else {
                return
            }
            
            urlResponseSaver.responseToLocalUrl(for: response, url: downloadLocation)
                .flatMapCompletable { localURL in
                    self.keySetDownloadProcessor.process(identifier: keySetIdentifier, url: localURL)
                }
                .subscribe()
                .disposed(by: disposeBag)
        }
    }
}

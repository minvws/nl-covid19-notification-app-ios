/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Security
import RxSwift
import ENFoundation

final class NetworkManagerURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionDelegateProtocol, URLSessionDownloadDelegate, Logging {
    
    var urlSessionBackgroundCompletionHandler: (() -> ())?
    let urlResponseSaver: URLResponseSaving
    let keySetDownloadProcessor: KeySetDownloadProcessing
    
    /// Initialise session delegate with certificate used for SSL pinning
    init(configurationProvider: NetworkConfigurationProvider,
         urlResponseSaver: URLResponseSaving,
         keySetDownloadProcessor: KeySetDownloadProcessing) {
        self.configurationProvider = configurationProvider
        self.urlResponseSaver = urlResponseSaver
        self.keySetDownloadProcessor = keySetDownloadProcessor
    }
    
    // MARK: - URLSessionDelegate
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> ()) {
        
        guard let localFingerprints = configurationProvider.configuration.sslFingerprints(forHost: challenge.protectionSpace.host),
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            // no pinning
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let policies = [SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)]
        SecTrustSetPolicies(serverTrust, policies as CFTypeRef)
        
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        guard
            SecTrustEvaluateWithError(serverTrust, nil),
            certificateCount > 0,
            let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, certificateCount - 1), // get topmost certificate in chain
            let fingerprint = Certificate(certificate: serverCertificate).fingerprint else {
            // invalid server trust
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        guard localFingerprints.contains(fingerprint) else {
            // signatures don't match
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // all good
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        logTrace()
        
        DispatchQueue.main.async {
            self.urlSessionBackgroundCompletionHandler?()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {}
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {}
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // Make sure the download belongs to a known url session identifier
        guard let sessionConfigurationIdentifier = session.configuration.identifier,
              let urlSessionIdentifier = URLSessionIdentifier(rawValue: sessionConfigurationIdentifier),
              let response = downloadTask.response else {
            return
        }
                
        switch urlSessionIdentifier {
        case .keysetURLSession:
            guard let keySetIdentifier = downloadTask.originalRequest?.url?.pathComponents.last else {
                return
            }
            
            urlResponseSaver.responseToLocalUrl(for: response, url: location)
                .flatMapCompletable { localURL in
                    self.keySetDownloadProcessor.process(identifier: keySetIdentifier, url: localURL)
                }
                .subscribe()
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Private
    
    private let configurationProvider: NetworkConfigurationProvider
    private let disposeBag = DisposeBag()
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Security
import RxSwift

final class NetworkManagerURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionDelegateProtocol {
    
    /// Initialise session delegate with certificate used for SSL pinning
    init(configurationProvider: NetworkConfigurationProvider) {
        self.configurationProvider = configurationProvider
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
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {}
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {}
        
    // MARK: - Private
    
    private let configurationProvider: NetworkConfigurationProvider
}


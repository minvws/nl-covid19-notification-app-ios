/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

/// @mockable(history:isApplicable=true;process = true)
protocol VerifySignatureResponseHandlerProtocol {
    func isApplicable(for response: URLResponseProtocol, input: URL) -> Bool
    func process(response: URLResponseProtocol, input: URL) -> Single<URL>
}

final class VerifySignatureResponseHandler: VerifySignatureResponseHandlerProtocol {
    
    private let cryptoUtility: CryptoUtility
    private let fileManager: FileManaging
    
    private let signatureFilename = "content.sig"
    private let contentFilename = "content.bin"
    private let tekFilename = "export.bin"
    
    init(cryptoUtility: CryptoUtility,
         fileManager: FileManaging) {
        self.cryptoUtility = cryptoUtility
        self.fileManager = fileManager
    }
    
    // MARK: - RxVerifySignatureResponseHandlerProtocol
    
    func isApplicable(for response: URLResponseProtocol, input: URL) -> Bool {
        return true
    }
    
    func process(response: URLResponseProtocol, input: URL) -> Single<URL> {
        guard let fileURLs = getFileURLs(from: input) else {
            return .error(NetworkResponseHandleError.invalidSignature)
        }
        
        let (signatureFileUrl, binaryFileUrl) = fileURLs
        
        guard
            let signatureData = try? Data(contentsOf: signatureFileUrl),
            let binaryData = try? Data(contentsOf: binaryFileUrl) else {
            return .error(NetworkResponseHandleError.invalidSignature)
        }
        
        return .create { observer in
            self.cryptoUtility.validate(data: binaryData,
                                        signature: signatureData) { isValid in
                
                if isValid {
                    observer(.success(input))
                } else {
                    observer(.failure(NetworkResponseHandleError.invalidSignature))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Private
    
    private func getFileURLs(from url: URL) -> (signatureFileUrl: URL, contentFileUrl: URL)? {
        var isFolder = ObjCBool(false)
        
        // verify signature file
        let signatureFileUrl = url.appendingPathComponent(signatureFilename)
        guard fileManager.fileExists(atPath: signatureFileUrl.path, isDirectory: &isFolder), isFolder.boolValue == false else {
            return nil
        }
        
        var binaryFileUrl = url.appendingPathComponent(contentFilename)
        if fileManager.fileExists(atPath: binaryFileUrl.path, isDirectory: &isFolder), isFolder.boolValue == false {
            return (signatureFileUrl, binaryFileUrl)
        }
        
        binaryFileUrl = url.appendingPathComponent(tekFilename)
        if fileManager.fileExists(atPath: binaryFileUrl.path, isDirectory: &isFolder), isFolder.boolValue == false {
            return (signatureFileUrl, binaryFileUrl)
        }
        
        return nil
    }
}

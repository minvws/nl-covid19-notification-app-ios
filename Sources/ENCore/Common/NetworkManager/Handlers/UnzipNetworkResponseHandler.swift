/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift
import ZIPFoundation
import ENFoundation

/// @mockable(history:isApplicable=true;process = true)
protocol UnzipNetworkResponseHandlerProtocol {
    func isApplicable(for response: URLResponseProtocol, input: URL) -> Bool
    func process(response: URLResponseProtocol, input: URL) -> Single<URL>
}

final class UnzipNetworkResponseHandler: UnzipNetworkResponseHandlerProtocol, Logging {
   
    init(fileManager: FileManaging) {
        self.fileManager = fileManager
    }

    // MARK: - RxUnzipNetworkResponseHandlerProtocol

    func isApplicable(for response: URLResponseProtocol, input: URL) -> Bool {
        guard let response = response as? HTTPURLResponse,
            let contentTypeHeader = response.allHeaderFields[HTTPHeaderKey.contentType.rawValue] as? String else {
            return false
        }

        return contentTypeHeader.lowercased() == HTTPContentType.zip.rawValue.lowercased()
    }
    
    func process(response: URLResponseProtocol, input: URL) -> Single<URL> {
        
        logDebug("unzipping file from \(input)")
        
        guard let destinationURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString) else {
            return .error(NetworkResponseHandleError.cannotUnzip)
        }

        let start = CFAbsoluteTimeGetCurrent()
        
        var skipCRC32 = false
        #if DEBUG
            skipCRC32 = true
        #endif
        
        do {
            
            try fileManager.createDirectory(at: input, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: input, to: destinationURL, skipCRC32: skipCRC32, progress: nil, preferredEncoding: nil)
            
            let diff = CFAbsoluteTimeGetCurrent() - start
            logDebug("KSSPEED Unzipping file Took \(diff) seconds")
        }
        catch {
            logError("unzip error: \(error) for file \(input)")
            return .error(NetworkResponseHandleError.cannotUnzip)
        }
        
        return .just(destinationURL)
    }

    // MARK: - Private

    private let fileManager: FileManaging
}

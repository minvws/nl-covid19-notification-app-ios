/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import ZIPFoundation

/// @mockable(history:isApplicable=true;process = true)
protocol UnzipNetworkResponseHandlerProtocol {
    func isApplicable(for response: URLResponseProtocol, input: URL) -> Bool
    func process(response: URLResponseProtocol, input: URL) -> Single<URL>
}

final class UnzipNetworkResponseHandler: UnzipNetworkResponseHandlerProtocol, Logging {

    init(fileManager: FileManaging,
         localPathProvider: LocalPathProviding) {
        self.fileManager = fileManager
        self.localPathProvider = localPathProvider
    }

    // MARK: - UnzipNetworkResponseHandlerProtocol

    func isApplicable(for response: URLResponseProtocol, input: URL) -> Bool {
        return response.contentType?.lowercased() == HTTPContentType.zip.rawValue.lowercased()
    }

    func process(response: URLResponseProtocol, input: URL) -> Single<URL> {

        logDebug("unzipping file from \(input)")

        let destinationURL = localPathProvider.temporaryDirectoryUrl.appendingPathComponent(fileManager.generateRandomUUIDFileName())

        var skipCRC32 = false
        #if DEBUG
            skipCRC32 = true
        #endif

        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: input, to: destinationURL, skipCRC32: skipCRC32, progress: nil, preferredEncoding: nil)
        } catch {
            logError("unzip error: \(error) for file \(input)")
            return .error(NetworkResponseHandleError.cannotUnzip)
        }

        return .just(destinationURL)
    }

    // MARK: - Private

    private let fileManager: FileManaging
    private let localPathProvider: LocalPathProviding
}

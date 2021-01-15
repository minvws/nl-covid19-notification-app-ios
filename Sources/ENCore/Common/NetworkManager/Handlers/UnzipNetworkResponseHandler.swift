/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift
import ZIPFoundation

/// @mockable
protocol UnzipNetworkResponseHandlerProtocol {
    func isApplicable(for response: URLResponse, input: URL) -> Bool
    func process(response: URLResponse, input: URL) -> Single<URL>
}

final class UnzipNetworkResponseHandler: UnzipNetworkResponseHandlerProtocol {

    init(fileManager: FileManaging) {
        self.fileManager = fileManager
    }

    // MARK: - RxUnzipNetworkResponseHandlerProtocol

    func isApplicable(for response: URLResponse, input: URL) -> Bool {
        guard let response = response as? HTTPURLResponse else {
            return false
        }

        return response.value(forHTTPHeaderField: HTTPHeaderKey.contentType.rawValue) == HTTPContentType.zip.rawValue
    }

    func process(response: URLResponse, input: URL) -> Single<URL> {
        guard let destinationURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString) else {
            return .error(NetworkResponseHandleError.cannotUnzip)
        }

        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: input, to: destinationURL, skipCRC32: false, progress: nil, preferredEncoding: nil)
        } catch {
            return .error(NetworkResponseHandleError.cannotUnzip)
        }

        return .just(destinationURL)
    }

    // MARK: - Private

    private let fileManager: FileManaging
}

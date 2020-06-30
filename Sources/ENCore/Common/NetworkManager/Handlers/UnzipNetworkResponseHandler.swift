/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import ZIPFoundation

final class UnzipNetworkResponseHandler: NetworkResponseHandler {
    typealias Input = URL
    typealias Output = URL

    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }

    // MARK: - NetworkResponseHandler

    func isApplicable(for response: URLResponse, input: URL) -> Bool {
        guard let response = response as? HTTPURLResponse else {
            return false
        }

        return response.value(forHTTPHeaderField: HTTPHeaderKey.contentType.rawValue) == HTTPContentType.zip.rawValue
    }

    func process(response: URLResponse, input: URL) -> AnyPublisher<URL, NetworkResponseHandleError> {
        guard let destinationURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString) else {
            return Fail(error: .cannotUnzip).eraseToAnyPublisher()
        }

        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: input, to: destinationURL)
        } catch {
            return Fail(error: .cannotUnzip).eraseToAnyPublisher()
        }

        return Just(destinationURL)
            .setFailureType(to: NetworkResponseHandleError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private let fileManager: FileManager // TODO: Make mockable
}

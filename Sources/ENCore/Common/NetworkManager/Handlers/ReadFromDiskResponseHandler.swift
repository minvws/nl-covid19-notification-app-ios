/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

final class ReadFromDiskResponseHandler: NetworkResponseHandler {
    typealias Input = URL
    typealias Output = Data

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    // MARK: - NetworkResponseHandler

    func isApplicable(for response: URLResponse, input: URL) -> Bool {
        return contentFileUrl(from: input) != nil
    }

    func process(response: URLResponse, input: URL) throws -> Data {
        guard
            let url = contentFileUrl(from: input),
            let data = try? Data(contentsOf: url) else {
            throw NetworkResponseHandleError.cannotDeserialize
        }

        return data
    }

    // MARK: - Private

    private func contentFileUrl(from url: URL) -> URL? {
        var isDirectory: ObjCBool = .init(false)

        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return nil
        }

        guard isDirectory.boolValue else {
            return url
        }

        let contentFileUrl = url.appendingPathComponent(contentFilename)

        guard fileManager.fileExists(atPath: contentFileUrl.path) else {
            return nil
        }

        return contentFileUrl
    }

    private let fileManager: FileManager
    private let contentFilename = "content.bin"
}

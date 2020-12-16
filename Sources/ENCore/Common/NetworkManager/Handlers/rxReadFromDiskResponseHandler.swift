/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

final class RxReadFromDiskResponseHandler: RxNetworkResponseHandler {
    typealias Input = URL
    typealias Output = Data

    init(fileManager: FileManaging) {
        self.fileManager = fileManager
    }

    // MARK: - NetworkResponseHandler

    func isApplicable(for response: URLResponse, input: URL) -> Bool {
        return contentFileUrl(from: input) != nil
    }

    func process(response: URLResponse, input: Input) -> Observable<Output> {
        guard
            let url = contentFileUrl(from: input),
            let data = try? Data(contentsOf: url) else {
            return .error(NetworkResponseHandleError.cannotDeserialize)
        }

        return .just(data)
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

    private let fileManager: FileManaging
    private let contentFilename = "content.bin"
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

final class VerifySignatureResponseHandler: NetworkResponseHandler {
    private let signatureFilename = "content.sig"
    private let contentFilename = "content.bin"
    private let tekFilename = "export.bin"

    init(cryptoUtility: CryptoUtility) {
        self.cryptoUtility = cryptoUtility
    }

    // MARK: - NetworkResponseHandler

    func isApplicable(for response: URLResponse, input: URL) -> Bool {
        return true
    }

    func process(response: URLResponse, input: URL) -> AnyPublisher<URL, NetworkResponseHandleError> {
        guard let fileURLs = getFileURLs(from: input) else {
            return Fail(error: .invalidSignature).eraseToAnyPublisher()
        }

        let (signatureFileUrl, binaryFileUrl) = fileURLs

        guard
            let signatureData = try? Data(contentsOf: signatureFileUrl),
            let binaryData = try? Data(contentsOf: binaryFileUrl) else {
            return Fail(error: .invalidSignature).eraseToAnyPublisher()
        }

        return Future { promise in
            self.cryptoUtility.validate(data: binaryData,
                                        signature: signatureData) { isValid in
                promise(isValid ? Result.success(input) : Result.failure(.invalidSignature))
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func getFileURLs(from url: URL) -> (signatureFileUrl: URL, contentFileUrl: URL)? {
        var isFolder = ObjCBool(false)

        // verify signature file
        let signatureFileUrl = url.appendingPathComponent(signatureFilename)
        guard FileManager.default.fileExists(atPath: signatureFileUrl.path, isDirectory: &isFolder), isFolder.boolValue == false else {
            return nil
        }

        var binaryFileUrl = url.appendingPathComponent(contentFilename)
        if FileManager.default.fileExists(atPath: binaryFileUrl.path, isDirectory: &isFolder), isFolder.boolValue == false {
            return (signatureFileUrl, binaryFileUrl)
        }

        binaryFileUrl = url.appendingPathComponent(tekFilename)
        if FileManager.default.fileExists(atPath: binaryFileUrl.path, isDirectory: &isFolder), isFolder.boolValue == false {
            return (signatureFileUrl, binaryFileUrl)
        }

        return nil
    }

    private let cryptoUtility: CryptoUtility
}

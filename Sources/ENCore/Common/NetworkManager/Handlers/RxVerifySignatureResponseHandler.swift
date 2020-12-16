/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

final class RxVerifySignatureResponseHandler: RxNetworkResponseHandler {
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

    func process(response: URLResponse, input: URL) -> Observable<URL> {
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
                    observer.onNext(input)
                } else {
                    observer.onError(NetworkResponseHandleError.invalidSignature)
                }
                observer.on(.completed)
            }

            return Disposables.create()
        }
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

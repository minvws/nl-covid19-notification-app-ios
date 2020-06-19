/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum VerifySignatureError: Error {
    case cantVerify
}

final class VerifySignatureResponseHandler {

    enum TEKFiles: String {
        case binary = "export.bin"
        case signatureApple = "export.sig"
        case signatureRijksoverheid = "content.sig"
    }

    enum ContentFiles: String {
        case binary = "content.bin"
        case signatureRijksoverheid = "content.sig"
    }

    /// Methods to verify file signature, returns true for now (signature check disabled)
    /// - Parameter urls: unzipped file urls
    /// - Returns: signature match
    func handle(urls: [URL]) -> Bool {

        let fileNames = urls.map { $0.lastPathComponent }

        // Apple TEK file
        if fileNames.contains(TEKFiles.binary.rawValue),
            fileNames.contains(TEKFiles.signatureApple.rawValue),
            fileNames.contains(TEKFiles.signatureRijksoverheid.rawValue) {
            return self.verifySignature()
            // Self signed files
        } else if fileNames.contains(ContentFiles.binary.rawValue),
            fileNames.contains(ContentFiles.signatureRijksoverheid.rawValue) {
            return self.verifySignature()
        }

        // true is the files didnt match, no signature
        return true
    }

    private func verifySignature() -> Bool {
        return true
    }
}

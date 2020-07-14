/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol SignatureValidating {
    func validate(signature: Data, content: Data) -> Bool
}

final class SignatureValidator: SignatureValidating {
    private let openssl = OpenSSL()

    func validate(signature: Data, content: Data) -> Bool {
        guard let rootCertificateData = validatedRootCertificateData() else {
            return false
        }

        return openssl.validatePKCS7Signature(signature,
                                              contentData: content,
                                              certificateData: rootCertificateData)
    }

    private func validatedRootCertificateData() -> Data? {
        guard let certificateData = SignatureConfiguration.rootCertificateData else {
            return nil
        }

        guard openssl.validateSerialNumber(SignatureConfiguration.rootSerial,
                                           forCertificateData: certificateData) else {
            return nil
        }

        guard openssl.validateSubjectKeyIdentifier(SignatureConfiguration.rootSubjectKeyIdentifier,
                                                   forCertificateData: certificateData) else {
            return nil
        }

        return certificateData
    }
}

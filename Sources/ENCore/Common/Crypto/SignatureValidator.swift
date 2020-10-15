/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol SignatureValidating {
    func validate(signature: Data, content: Data) -> Bool
}

final class SignatureValidator: SignatureValidating, Logging {
    private let openssl = OpenSSL()
    private let signatureConfiguration: SignatureConfiguration

    init(signatureConfiguration: SignatureConfiguration = DefaultSignatureConfiguration()) {
        self.signatureConfiguration = signatureConfiguration
    }

    func validate(signature: Data, content: Data) -> Bool {

        guard let rootCertificateData = validatedRootCertificateData() else {
            return false
        }

        guard openssl.validatePKCS7Signature(
            signature,
            contentData: content,
            certificateData: rootCertificateData,
            authorityKeyIdentifier: signatureConfiguration.authorityKeyIdentifier,
            requiredCommonNameContent: signatureConfiguration.commonNameContent,
            requiredCommonNameSuffix: signatureConfiguration.commonNameSuffix) else {
            logError("PKCS7Signature is invalid")
            return false
        }

        return true
    }

    private func validatedRootCertificateData() -> Data? {

        guard let rootCertificateData = signatureConfiguration.rootCertificateData else {
            return nil
        }

        guard openssl.validateSerialNumber(signatureConfiguration.rootSerial,
                                           forCertificateData: rootCertificateData) else {
            return nil
        }

        guard openssl.validateSubjectKeyIdentifier(signatureConfiguration.rootSubjectKeyIdentifier,
                                                   forCertificateData: rootCertificateData) else {
            return nil
        }

        return rootCertificateData
    }
}

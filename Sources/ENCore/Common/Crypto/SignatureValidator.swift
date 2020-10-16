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
    func validate(signature: Data, content: Data, validateRootCertificate: Bool) -> SignatureValidationResult
}

final class SignatureValidator: SignatureValidating, Logging {
    private let openssl = OpenSSL()
    private let signatureConfiguration: SignatureConfiguration

    init(signatureConfiguration: SignatureConfiguration = DefaultSignatureConfiguration()) {
        self.signatureConfiguration = signatureConfiguration
    }

    func validate(signature: Data, content: Data, validateRootCertificate: Bool) -> SignatureValidationResult {

        guard let rootCertificateData = signatureConfiguration.rootCertificateData else {
            return SignatureValidationResult.SIGNATUREVALIDATIONRESULT_GENERICERROR
        }

        if validateRootCertificate {
            guard openssl.validateSerialNumber(signatureConfiguration.rootSerial,
                                               forCertificateData: rootCertificateData) else {
                return SignatureValidationResult.SIGNATUREVALIDATIONRESULT_GENERICERROR
            }

            guard openssl.validateSubjectKeyIdentifier(signatureConfiguration.rootSubjectKeyIdentifier,
                                                       forCertificateData: rootCertificateData) else {
                return SignatureValidationResult.SIGNATUREVALIDATIONRESULT_GENERICERROR
            }
        }

        return openssl.validatePKCS7Signature(
            signature,
            contentData: content,
            certificateData: rootCertificateData,
            authorityKeyIdentifier: signatureConfiguration.authorityKeyIdentifier,
            requiredCommonNameContent: signatureConfiguration.commonNameContent,
            requiredCommonNameSuffix: signatureConfiguration.commonNameSuffix)
    }
}

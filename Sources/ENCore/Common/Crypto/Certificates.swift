/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CryptoKit
import Foundation
import Security

struct Certificate {
    typealias Signature = String

    let secCertificate: SecCertificate

    init?(string: String) {
        let content = string.replacingOccurrences(of: "\n", with: "")

        guard let data = Data(base64Encoded: content),
            let secCertificate = SecCertificateCreateWithData(nil, data as CFData) else {
            return nil
        }

        self.secCertificate = secCertificate
    }

    init(certificate: SecCertificate) {
        self.secCertificate = certificate
    }

    var signature: Signature? {
        let data = SecCertificateCopyData(secCertificate)
        return Data(SHA256.hash(data: data as Data)).base64EncodedString()
    }
}

extension Certificate {
    struct SSL {
        static let apiAccSignature: Certificate.Signature = "xblTCeUhNLA8ALWn2MSgGLCzINiTAuiJglCtNcw4YOE="
        static let cdnAccSignature: Certificate.Signature = "Fq9XqfZ2sKsSYJWqXrre8iqzERnWRKyVzUuT2/Pyaus="
    }
}

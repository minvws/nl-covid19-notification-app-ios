/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Security

struct Certificate {
    typealias Fingerprint = String

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

    var fingerprint: Fingerprint? {
        let data = SecCertificateCopyData(secCertificate) as Data
        return data.sha256.base64EncodedString()
    }
}

extension Certificate {
    struct SSL {
        static let apiFingerprint: Certificate.Fingerprint = "PE+wuVq4swAy9DK4b1Nf4XLBhdD9OYZYN882GH+m9Cg="
        static let apiV2Fingerprint: Certificate.Fingerprint = "TSSRQUz+lWdG7Ezvps9vcuKKEylDL52KkHrEy12twVo="
        static let cdnFingerprint: Certificate.Fingerprint = "PE+wuVq4swAy9DK4b1Nf4XLBhdD9OYZYN882GH+m9Cg="
        static let cdnV2V3Fingerprint: Certificate.Fingerprint = "TSSRQUz+lWdG7Ezvps9vcuKKEylDL52KkHrEy12twVo="
    }
}

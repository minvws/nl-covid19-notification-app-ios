/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol SignatureConfiguration {
    var rootCertificateData: Data? { get }
    var rootSubjectKeyIdentifier: Data { get }
    var authorityKeyIdentifier: Data { get }
    var rootSerial: UInt64 { get }
    var commonNameContent: String { get }
    var commonNameSuffix: String { get }
}

final class DefaultSignatureConfiguration: SignatureConfiguration {

    let commonNameContent = "coronamelder"
    let commonNameSuffix = ".nl"

    var rootCertificateData: Data? {
        guard let localUrl = Bundle(for: DefaultSignatureConfiguration.self).url(forResource: "nl-root", withExtension: "pem") else {
            return nil
        }

        return try? Data(contentsOf: localUrl)
    }

    // The publicly known default SubjectKeyIdentifier for the root CA
    var rootSubjectKeyIdentifier: Data {
        // 04:14:2A:FD:B9:2B:1E:FA:C3:84:87:06:DB:81:FF:86:97:75:0D:EB:01:8B
        return Data([0x04, 0x14, 0x2a, 0xfd, 0xb9, 0x2b, 0x1e, 0xfa, 0xc3, 0x84, 0x87, 0x06, 0xdb, 0x81, 0xff, 0x86, 0x97, 0x75, 0x0d, 0xeb, 0x01, 0x8b])
    }

    // The publicly known default AuthorityKeyIdentifier for the issuer that issued the signing certificate
    var authorityKeyIdentifier: Data {
        // 04:14:B8:D4:4C:9F:A8:5B:6E:DA:25:A7:68:8E:EF:8C:46:1A:FE:1F:53:65
        return Data([0x04, 0x14, 0xb8, 0xd4, 0x4c, 0x9f, 0xa8, 0x5b, 0x6e, 0xda, 0x25, 0xa7, 0x68, 0x8e, 0xef, 0x8c, 0x46, 0x1a, 0xfe, 0x1f, 0x53, 0x65])
    }

    var rootSerial: UInt64 {
        return 10004001
    }
}

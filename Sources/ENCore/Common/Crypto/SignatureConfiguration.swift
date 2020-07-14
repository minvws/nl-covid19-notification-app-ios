/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

final class SignatureConfiguration {
    static var rootCertificateData: Data? {
        guard let localUrl = Bundle(for: SignatureConfiguration.self).url(forResource: "nl-root", withExtension: "pem") else {
            return nil
        }

        return try? Data(contentsOf: localUrl)
    }

    static var rootSubjectKeyIdentifier: Data {
        // 04:14:54:AD:FA:C7:92:57:AE:CA:35:9C:2E:12:FB:E4:BA:5D:20:DC:94:57
        return Data([0x04, 0x14, 0x54, 0xad, 0xfa, 0xc7, 0x92, 0x57, 0xae, 0xca, 0x35, 0x9c, 0x2e, 0x12, 0xfb, 0xe4, 0xba, 0x5d, 0x20, 0xdc, 0x94, 0x57])
    }

    static var rootSerial: UInt64 {
        return 10003001
    }
}

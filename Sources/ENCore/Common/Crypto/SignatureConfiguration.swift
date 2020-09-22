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
        // 04:14:fe:ab:00:90:98:9e:24:fc:a9:cc:1a:8a:fb:27:b8:bf:30:6e:a8:3b
        return Data([0x04, 0x14, 0xfe, 0xab, 0x00, 0x90, 0x98, 0x9e, 0x24, 0xfc, 0xa9, 0xcc, 0x1a, 0x8a, 0xfb, 0x27, 0xb8, 0xbf, 0x30, 0x6e, 0xa8, 0x3b])
    }

    static var authorityKeyIdentifier: Data {
        // 04:14:08:4a:aa:bb:99:24:6f:be:5b:07:f1:a5:8a:99:5b:2d:47:ef:b9:3c
        return Data([0x04, 0x14, 0x08, 0x4a, 0xaa, 0xbb, 0x99, 0x24, 0x6f, 0xbe, 0x5b, 0x07, 0xf1, 0xa5, 0x8a, 0x99, 0x5b, 0x2d, 0x47, 0xef, 0xb9, 0x3c])
    }

    static var rootSerial: UInt64 {
        return 10000013
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class CertificatesTests: TestCase {

    func test_fingerprint() throws {
        let filePath = Bundle(for: CertificatesTests.self).path(forResource: "TestCertificate", ofType: "der")!
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let secCertificate = SecCertificateCreateWithData(nil, data as CFData)!
        let certificate = Certificate(certificate: secCertificate)
        let fingerprint = certificate.fingerprint
        XCTAssertEqual(fingerprint, "KenqWbuH5x8pcDfNRzfspUfonUyR/MjBU+orR0pU0cE=")
    }
}

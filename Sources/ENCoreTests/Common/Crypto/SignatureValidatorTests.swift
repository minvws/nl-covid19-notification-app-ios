/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

final class SignatureValidatorTests: XCTestCase {

    func test_signatureValidator_withValidSignature() {
        let signatureValidator = SignatureValidator()

        let validSignature = dataFromFile(withName: "signature", fileType: "sig")
        let content = dataFromFile(withName: "export", fileType: "bin")

        let result = signatureValidator.validate(signature: validSignature, content: content)

        XCTAssertTrue(result)
    }

    func test_signatureValidator_withInvalidSignature() {
        let signatureValidator = SignatureValidator()

        let signature = dataFromFile(withName: "signature-incorrectcommonname", fileType: "sig")
        let content = dataFromFile(withName: "export", fileType: "bin")

        let result = signatureValidator.validate(signature: signature, content: content)

        XCTAssertFalse(result)
    }

    // This test is using the new certificates sent by yorim.
    func test_signatureValidator_withInvalidSignature_new() throws {
        let signature = dataFromFile(withName: "CNTestfile", fileType: "sig")
        let content = dataFromFile(withName: "CNTestfile", fileType: "txt")
        let rootCertificate = dataFromFile(withName: "testroot", fileType: "pem")

        let configurationMock = SignatureConfigurationMock()
        configurationMock.rootCertificateData = rootCertificate
        configurationMock.rootSubjectKeyIdentifier = "04143ebd1363a152e330842def2c1869ca979073d062".hexaData
        configurationMock.authorityKeyIdentifier = "301680143ebd1363a152e330842def2c1869ca979073d062".hexaData
        configurationMock.commonNameContent = "coronamelder"
        configurationMock.commonNameSuffix = ".nl"
//        configurationMock.rootSerial = 673612227079512554895200720572022748667272347336
//        configurationMock.rootSerial = 140491522854880

        let signatureValidator = SignatureValidator(signatureConfiguration: configurationMock)

        let result = signatureValidator.validate(signature: signature, content: content)

        XCTAssertFalse(result)
    }

    private func dataFromFile(withName fileName: String, fileType: String) -> Data {
        let url = URL(fileURLWithPath: Bundle(for: SignatureValidatorTests.self).path(forResource: fileName, ofType: fileType)!)
        return try! Data(contentsOf: url)
    }
}

private extension StringProtocol {
    var hexaData: Data { .init(hexa) }
    var hexaBytes: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex ..< endIndex], radix: 16)
        }
    }
}

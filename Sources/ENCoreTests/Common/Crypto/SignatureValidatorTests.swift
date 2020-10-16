/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

final class SignatureValidatorTests: XCTestCase {

    func test_signatureValidator_withEmbeddedRootCertificate() {
        let signatureValidator = SignatureValidator()

        let validSignature = dataFromFile(withName: "signature", fileType: "sig")
        let content = dataFromFile(withName: "export", fileType: "bin")

        let result = signatureValidator.validate(signature: validSignature, content: content, validateRootCertificate: true)

        XCTAssertEqual(result, .SIGNATUREVALIDATIONRESULT_SUCCESS)
    }

    func test_signatureValidator_incorrectCommonName() {
        let signature = dataFromFile(withName: "CNTestfile", fileType: "sig")
        let content = dataFromFile(withName: "CNTestfile", fileType: "txt")
        let rootCertificate = dataFromFile(withName: "testroot", fileType: "pem")

        let configurationMock = SignatureConfigurationMock()
        configurationMock.rootCertificateData = rootCertificate
        configurationMock.rootSubjectKeyIdentifier = "04143EBD1363A152E330842DEF2C1869CA979073D062".hexaData
        configurationMock.authorityKeyIdentifier = "04143EBD1363A152E330842DEF2C1869CA979073D062".hexaData
        configurationMock.commonNameContent = "CoronaMelder"
        configurationMock.commonNameSuffix = "nl"
        configurationMock.rootSerial = 1912602624

        let signatureValidator = SignatureValidator(signatureConfiguration: configurationMock)

        let result = signatureValidator.validate(signature: signature, content: content, validateRootCertificate: false)

        XCTAssertEqual(result, SignatureValidationResult.SIGNATUREVALIDATIONRESULT_INCORRECTCOMMONNAME)
    }

    func test_signatureValidator_chainBroken_byMissingAuthorityKeyIdentifier() {
        let signature = dataFromFile(withName: "CNTestfile-noaki", fileType: "sig")
        let content = dataFromFile(withName: "CNTestfile-noaki", fileType: "txt")
        let rootCertificate = dataFromFile(withName: "testroot-noaki", fileType: "pem")

        let configurationMock = SignatureConfigurationMock()
        configurationMock.rootCertificateData = rootCertificate
        configurationMock.rootSubjectKeyIdentifier = "0414F5E3DA7FADAB66396D90B7F1800129E3C91182BA".hexaData
        configurationMock.authorityKeyIdentifier = "0414F5E3DA7FADAB66396D90B7F1800129E3C91182BA".hexaData
        configurationMock.commonNameContent = "TestIncorrectCN"
        configurationMock.commonNameSuffix = ""
        configurationMock.rootSerial = 1912602624

        let signatureValidator = SignatureValidator(signatureConfiguration: configurationMock)

        let result = signatureValidator.validate(signature: signature, content: content, validateRootCertificate: false)

        XCTAssertEqual(result, .SIGNATUREVALIDATIONRESULT_INCORRECTAUTHORITYKEYIDENTIFIER)
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

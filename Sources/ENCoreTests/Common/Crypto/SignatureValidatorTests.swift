/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

final class SignatureValidatorTests: XCTestCase {

    func test_validateSignature_withDefaultSignatureConfiguration() {
        let validSignature = dataFromFile(withName: "signature-valid", fileType: "sig")
        let content = dataFromFile(withName: "content-valid", fileType: "bin")
        let signatureValidator = SignatureValidator(signatureConfiguration: DefaultSignatureConfiguration())

        let result = signatureValidator.validate(signature: validSignature, content: content, validateRootCertificate: true)

        XCTAssertEqual(result, .SIGNATUREVALIDATIONRESULT_SUCCESS)
    }

    func test_validateSignature_incorrectCommonName() {
        let signature = dataFromFile(withName: "signature-incorrectCommonName", fileType: "sig")
        let content = dataFromFile(withName: "content-incorrectCommonName", fileType: "txt")
        let rootCertificate = dataFromFile(withName: "rootcertificate-incorrectCommonName", fileType: "pem")

        let mockSignatureConfiguration = SignatureConfigurationMock()
        mockSignatureConfiguration.rootCertificateData = rootCertificate
        mockSignatureConfiguration.rootSubjectKeyIdentifier = "04143EBD1363A152E330842DEF2C1869CA979073D062".hexaData
        mockSignatureConfiguration.authorityKeyIdentifier = "04143EBD1363A152E330842DEF2C1869CA979073D062".hexaData
        mockSignatureConfiguration.commonNameContent = "CoronaMelder"
        mockSignatureConfiguration.commonNameSuffix = "nl"
        mockSignatureConfiguration.rootSerial = 1912602624

        let signatureValidator = SignatureValidator(signatureConfiguration: mockSignatureConfiguration)

        let result = signatureValidator.validate(signature: signature, content: content, validateRootCertificate: false)

        XCTAssertEqual(result, SignatureValidationResult.SIGNATUREVALIDATIONRESULT_INCORRECTCOMMONNAME)
    }

    func test_validateSignature_missingAuthorityKeyIdentifier() {
        let signature = dataFromFile(withName: "signature-noAuthorityKeyIdentifier", fileType: "sig")
        let content = dataFromFile(withName: "content-noAuthorityKeyIdentifier", fileType: "txt")
        let rootCertificate = dataFromFile(withName: "rootcertificate-noAuthorityKeyIdentifier", fileType: "pem")

        let mockSignatureConfiguration = SignatureConfigurationMock()
        mockSignatureConfiguration.rootCertificateData = rootCertificate
        mockSignatureConfiguration.rootSubjectKeyIdentifier = "0414F5E3DA7FADAB66396D90B7F1800129E3C91182BA".hexaData
        mockSignatureConfiguration.authorityKeyIdentifier = "0414F5E3DA7FADAB66396D90B7F1800129E3C91182BA".hexaData
        mockSignatureConfiguration.commonNameContent = "TestIncorrectCN"
        mockSignatureConfiguration.commonNameSuffix = ""
        mockSignatureConfiguration.rootSerial = 1912602624

        let signatureValidator = SignatureValidator(signatureConfiguration: mockSignatureConfiguration)

        let result = signatureValidator.validate(signature: signature, content: content, validateRootCertificate: false)

        XCTAssertEqual(result, .SIGNATUREVALIDATIONRESULT_INCORRECTAUTHORITYKEYIDENTIFIER)
    }

    func test_validateSignature_missinglink() {
        let signature = dataFromFile(withName: "signature-missinglink", fileType: "sig")
        let content = dataFromFile(withName: "content-missinglink", fileType: "txt")
        let rootCertificate = dataFromFile(withName: "rootcertificate-missinglink", fileType: "pem")

        let mockSignatureConfiguration = SignatureConfigurationMock()
        mockSignatureConfiguration.rootCertificateData = rootCertificate
        mockSignatureConfiguration.rootSubjectKeyIdentifier = "0414E3AC978E46443441C26E3121C05691BB7C333A2B".hexaData
        mockSignatureConfiguration.authorityKeyIdentifier = "0414E3AC978E46443441C26E3121C05691BB7C333A2B".hexaData
        mockSignatureConfiguration.commonNameContent = "TestLeaf"
        mockSignatureConfiguration.commonNameSuffix = ""
        mockSignatureConfiguration.rootSerial = 1912602624

        let signatureValidator = SignatureValidator(signatureConfiguration: mockSignatureConfiguration)

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

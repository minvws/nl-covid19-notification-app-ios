/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

final class SignatureValidatorTests: XCTestCase {
    private var validSignature: Data!
    private var invalidSignature: Data!
    private var export: Data!
    private let signatureValidator = SignatureValidator()

    override func setUp() {
        super.setUp()

        let validSignatureUrl = URL(fileURLWithPath: Bundle(for: SignatureValidatorTests.self).path(forResource: "signature", ofType: "sig")!)
        let invalidSignatureUrl = URL(fileURLWithPath: Bundle(for: SignatureValidatorTests.self).path(forResource: "signature-incorrectcommonname", ofType: "sig")!)

        let exportUrl = URL(fileURLWithPath: Bundle(for: SignatureValidatorTests.self).path(forResource: "export", ofType: "bin")!)

        validSignature = try! Data(contentsOf: validSignatureUrl)
        invalidSignature = try! Data(contentsOf: invalidSignatureUrl)
        export = try! Data(contentsOf: exportUrl)
    }

    func test_signatureValidator_withValidSignature() {
        XCTAssertTrue(signatureValidator.validate(signature: validSignature, content: export))
    }

    func test_signatureValidator_withInvalidSignature() {
        XCTAssertFalse(signatureValidator.validate(signature: invalidSignature, content: export))
    }
}

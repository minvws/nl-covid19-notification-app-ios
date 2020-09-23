/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

final class SignatureValidatorTests: XCTestCase {
    private var content: Data!
    private var export: Data!
    private let signatureValidator = SignatureValidator()

    override func setUp() {
        super.setUp()

        let contentUrl = URL(fileURLWithPath: Bundle(for: SignatureValidatorTests.self).path(forResource: "content", ofType: "sig")!)
        let exportUrl = URL(fileURLWithPath: Bundle(for: SignatureValidatorTests.self).path(forResource: "export", ofType: "bin")!)

        content = try! Data(contentsOf: contentUrl)
        export = try! Data(contentsOf: exportUrl)
    }

    func test_signatureValidator() {
        XCTAssertTrue(signatureValidator.validate(signature: content, content: export))
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class JSONDecoder_DecodingTests: TestCase {

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromUpperCamelCase
        return decoder
    }

    func test_convertFromUpperCamelCase_withUppercasedKey() throws {
        // Arrange
        // json key is uppercased on purposes and does not match the casing of DecodingTestObject
        let encodedStringData = "{\"SomeString\": \"blah\"}".data(using: .utf8)!

        // Act
        let result = try decoder.decode(DecodingTestObject.self, from: encodedStringData)

        // Assert
        XCTAssertEqual(result.someString, "blah")
    }

    func test_convertFromUpperCamelCase_withLowercasedKey() throws {
        // Arrange
        let encodedStringData = "{\"someString\": \"blah\"}".data(using: .utf8)!

        // Act
        let result = try decoder.decode(DecodingTestObject.self, from: encodedStringData)

        // Assert
        XCTAssertEqual(result.someString, "blah")
    }

    private struct DecodingTestObject: Codable {
        let someString: String
    }
}

/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import ENFoundation

class FoundationExtensionsTests: XCTestCase {

    func test_stringAsGGDkey_with6Digits() {
        // Arrange
        let input = "123-456"
        
        // Act
        let output = input.asGGDkey
        
        // Assert
        XCTAssertEqual(output, "123-456")
    }
    
    func test_stringAsGGDkey_with7Digits() {
        // Arrange
        let input = "1234567"
        
        // Act
        let output = input.asGGDkey
        
        // Assert
        XCTAssertEqual(output, "123-45-67")
    }
}

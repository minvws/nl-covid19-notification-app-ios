/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import ENCore

class LocalizationTests: TestCase {

    func test_statusNotifiedDaysAgo_english() {
        // Arrange
        let localeIdentifier = "en"
        
        // Act
        let result = String.statusNotifiedDaysAgo(days: 2, withLocaleIdentifier: localeIdentifier)
        
        // Assert
        XCTAssertEqual(result, "2 days ago")
    }
    
    func test_statusNotifiedDaysAgo_arabic() {
        // Arrange
        let localeIdentifier = "ar"
        
        // Act
        let result = String.statusNotifiedDaysAgo(days: 2, withLocaleIdentifier: localeIdentifier)
        
        // Assert
        XCTAssertEqual(result, "آخر٢")
    }

}

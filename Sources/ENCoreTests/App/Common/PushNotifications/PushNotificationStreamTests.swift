/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import ENCore

class PushNotificationStreamTests: TestCase {

    private var sut: PushNotificationStream!
    
    override func setUpWithError() throws {
        sut = PushNotificationStream()
    }

    func test_updateIdentifier_shouldNotDeDuplicateMessages() {
        // Arrange
        let subscriptionExpectation = expectation(description: "subscription called")
        subscriptionExpectation.expectedFulfillmentCount = 3
        let identifier = PushNotificationIdentifier.exposure
        
        sut.pushNotificationStream.subscribe { (receivedIdentifier) in
            XCTAssertEqual(receivedIdentifier.element, identifier)
            subscriptionExpectation.fulfill()
        }
        .disposed(by: disposeBag)
        
        // Act
        sut.update(identifier: identifier)
        sut.update(identifier: identifier)
        sut.update(identifier: identifier)
        
        // Assert
        waitForExpectations()
    }

}

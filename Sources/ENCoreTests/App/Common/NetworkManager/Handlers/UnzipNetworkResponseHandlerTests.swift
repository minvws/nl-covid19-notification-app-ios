/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import ENCore

class UnzipNetworkResponseHandlerTests: TestCase {

    private var sut: UnzipNetworkResponseHandler!
    private var mockFileManager: FileManagingMock!
    
    override func setUpWithError() throws {
        mockFileManager = FileManagingMock()
        sut = UnzipNetworkResponseHandler(fileManager: mockFileManager)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_process() {
        // Arrange
        let testEKS = URL(fileURLWithPath: Bundle(for: UnzipNetworkResponseHandlerTests.self).path(forResource: "test-eks", ofType: "zip")!)
        let mockResponse = URLResponseProtocolMock()
        
        let completionExpectation = expectation(description: "completion")
        
        // Act
        sut.process(response: mockResponse, input: testEKS)
            .subscribe { (_) in
                completionExpectation.fulfill()
            }
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations()
    }
}

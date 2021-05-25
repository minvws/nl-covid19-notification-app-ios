/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
import RxSwift

@testable import ENCore

class URLResponseSaverTests: TestCase {

    private var sut: URLResponseSaver!
    private var mockNetworkResponseHandlerProvider: NetworkResponseHandlerProviderMock!
    
    private var mockVerifySignatureResponseHandler: VerifySignatureResponseHandlerProtocolMock!
    private var mockUnzipNetworkResponseHandler: UnzipNetworkResponseHandlerProtocolMock!
    
    override func setUpWithError() throws {
        mockUnzipNetworkResponseHandler = UnzipNetworkResponseHandlerProtocolMock()
        mockVerifySignatureResponseHandler = VerifySignatureResponseHandlerProtocolMock()
                
        mockNetworkResponseHandlerProvider = NetworkResponseHandlerProviderMock()
        mockNetworkResponseHandlerProvider.unzipNetworkResponseHandler = mockUnzipNetworkResponseHandler
        mockNetworkResponseHandlerProvider.verifySignatureResponseHandler = mockVerifySignatureResponseHandler
        
        sut = URLResponseSaver(responseHandlerProvider: mockNetworkResponseHandlerProvider)
    }

    func test_responseToLocalUrl_shouldUnzipResponse() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        
        mockUnzipNetworkResponseHandler.isApplicableHandler = { _, _ in return true }
        mockUnzipNetworkResponseHandler.processHandler = { _, _ in
            return .just(URL(string: "http://www.someunzippedurl.com")!)
        }
        
        XCTAssertEqual(mockUnzipNetworkResponseHandler.isApplicableCallCount, 0)
        XCTAssertEqual(mockUnzipNetworkResponseHandler.processCallCount, 0)
        
        let urlResponse = URLResponseProtocolMock()
        let url = URL(string: "//local/url")!
        let backgroundThreadIfPossible = false
        
        // Act
        sut.responseToLocalUrl(for: urlResponse, url: url, backgroundThreadIfPossible: backgroundThreadIfPossible)
            .subscribe(onSuccess: { _ in
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockUnzipNetworkResponseHandler.isApplicableCallCount, 1)
        XCTAssertEqual(mockUnzipNetworkResponseHandler.processCallCount, 1)
        XCTAssertTrue((mockUnzipNetworkResponseHandler.processArgValues.first?.0 as? URLResponseProtocolMock) === urlResponse)
        XCTAssertEqual(mockUnzipNetworkResponseHandler.processArgValues.first?.1.absoluteString, "//local/url")
    }
    
    func test_responseToLocalUrl_shouldVerifySignature() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        
        mockVerifySignatureResponseHandler.isApplicableHandler = { _, _ in return true }
        mockVerifySignatureResponseHandler.processHandler = { _, _ in
            return .just(URL(string: "http://www.someverifiedurl.com")!)
        }
        
        XCTAssertEqual(mockVerifySignatureResponseHandler.isApplicableCallCount, 0)
        XCTAssertEqual(mockVerifySignatureResponseHandler.processCallCount, 0)
        
        let urlResponse = URLResponseProtocolMock()
        let url = URL(string: "//local/url")!
        let backgroundThreadIfPossible = false
        
        // Act
        sut.responseToLocalUrl(for: urlResponse, url: url, backgroundThreadIfPossible: backgroundThreadIfPossible)
            .subscribe(onSuccess: { _ in
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockVerifySignatureResponseHandler.isApplicableCallCount, 1)
        XCTAssertEqual(mockVerifySignatureResponseHandler.processCallCount, 1)
        XCTAssertTrue((mockVerifySignatureResponseHandler.processArgValues.first?.0 as? URLResponseProtocolMock) === urlResponse)
        XCTAssertEqual(mockVerifySignatureResponseHandler.processArgValues.first?.1.absoluteString, "//local/url")
    }
    
    func test_responseToLocalUrl_shouldNotCallHandlersIfNotApplicable() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        
        mockUnzipNetworkResponseHandler.isApplicableHandler = { _, _ in return false }
        mockVerifySignatureResponseHandler.isApplicableHandler = { _, _ in return false }
        
        XCTAssertEqual(mockUnzipNetworkResponseHandler.isApplicableCallCount, 0)
        XCTAssertEqual(mockVerifySignatureResponseHandler.isApplicableCallCount, 0)
        XCTAssertEqual(mockUnzipNetworkResponseHandler.processCallCount, 0)
        XCTAssertEqual(mockVerifySignatureResponseHandler.processCallCount, 0)
        
        let urlResponse = URLResponseProtocolMock()
        let url = URL(string: "//local/url")!
        let backgroundThreadIfPossible = false
        
        // Act
        sut.responseToLocalUrl(for: urlResponse, url: url, backgroundThreadIfPossible: backgroundThreadIfPossible)
            .subscribe(onSuccess: { _ in
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockUnzipNetworkResponseHandler.isApplicableCallCount, 1)
        XCTAssertEqual(mockVerifySignatureResponseHandler.isApplicableCallCount, 1)
        XCTAssertEqual(mockUnzipNetworkResponseHandler.processCallCount, 0)
        XCTAssertEqual(mockVerifySignatureResponseHandler.processCallCount, 0)
    }
}

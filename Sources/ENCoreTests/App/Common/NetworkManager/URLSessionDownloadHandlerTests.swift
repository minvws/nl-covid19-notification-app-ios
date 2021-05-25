/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest
import ENFoundation

class URLSessionDownloadHandlerTests: TestCase {
    
    private var sut: URLSessionDownloadHandler!
    
    private var mockURLResponseSaver: URLResponseSavingMock!
    private var mockKeySetDownloadProcessor: KeySetDownloadProcessingMock!
    
    override func setUpWithError() throws {
        
        mockURLResponseSaver = URLResponseSavingMock()
        mockKeySetDownloadProcessor = KeySetDownloadProcessingMock()
        
        sut = URLSessionDownloadHandler(urlResponseSaver: mockURLResponseSaver,
                                        keySetDownloadProcessor: mockKeySetDownloadProcessor)
    }
    
    func test_processDownload_shouldCallKeysetDownloadProcessor() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        
        mockURLResponseSaver.responseToLocalUrlForHandler = { _, _ in
            return .just(URL(string: "//local/url")!)
        }
        
        mockKeySetDownloadProcessor.processHandler = { _, _ in
            completionExpectation.fulfill()
            return .empty()
        }
        
        XCTAssertEqual(mockURLResponseSaver.responseToLocalUrlForCallCount, 0)
        XCTAssertEqual(mockKeySetDownloadProcessor.processCallCount, 0)
        
        let urlSessionIdentifier: URLSessionIdentifier = .keysetURLSession
        let response = URLResponseProtocolMock()
        let originalURL = URL(string: "http://www.someoriginalURL/keysetIdEnTiFiEr")!
        let downloadLocation = URL(string: "//some/local/file")!
        
        // Act
        sut.processDownload(urlSessionIdentifier: urlSessionIdentifier, response: response, originalURL: originalURL, downloadLocation: downloadLocation)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockURLResponseSaver.responseToLocalUrlForCallCount, 1)
        
        XCTAssertEqual(mockKeySetDownloadProcessor.processCallCount, 1)
        XCTAssertEqual(mockKeySetDownloadProcessor.processArgValues.first?.0, "keysetIdEnTiFiEr")
        XCTAssertEqual(mockKeySetDownloadProcessor.processArgValues.first?.1.absoluteString, "//local/url")
    }
    
    func test_processDownload_shouldNotCallKeysetDownloadProcessorWithoutKeySetIdentifier() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        completionExpectation.isInverted = true
                
        XCTAssertEqual(mockURLResponseSaver.responseToLocalUrlForCallCount, 0)
        XCTAssertEqual(mockKeySetDownloadProcessor.processCallCount, 0)
        
        let urlSessionIdentifier: URLSessionIdentifier = .keysetURLSession
        let response = URLResponseProtocolMock()
        let originalURL = URL(string: "http://www.someoriginalURL")!
        let downloadLocation = URL(string: "//some/local/file")!
        
        // Act
        sut.processDownload(urlSessionIdentifier: urlSessionIdentifier, response: response, originalURL: originalURL, downloadLocation: downloadLocation)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockURLResponseSaver.responseToLocalUrlForCallCount, 0)
        XCTAssertEqual(mockKeySetDownloadProcessor.processCallCount, 0)
    }
}

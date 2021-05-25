/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class NetworkManagerURLSessionDelegateTests: TestCase {

    private var sut: NetworkManagerURLSessionDelegate!

    private var mockNetworkConfigurationProvider: NetworkConfigurationProviderMock!
    private var mockURLSessionDownloadHandler: URLSessionDownloadHandlingMock!

    override func setUp() {
        super.setUp()

        mockNetworkConfigurationProvider = NetworkConfigurationProviderMock()
        mockURLSessionDownloadHandler = URLSessionDownloadHandlingMock()

        sut = NetworkManagerURLSessionDelegate(configurationProvider: mockNetworkConfigurationProvider,
                                               urlSessionDownloadHandler: mockURLSessionDownloadHandler)
    }
    
    func test_urlSessionDidFinishEvents_shouldCallBackgroundCompletionHandler() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        let completionHandler: () -> Void = {
            completionExpectation.fulfill()
        }
        
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        
        sut.receiveURLSessionBackgroundCompletionHandler(completionHandler: completionHandler)
                
        // Act
        sut.urlSessionDidFinishEvents(forBackgroundURLSession: urlSession)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
    }
}

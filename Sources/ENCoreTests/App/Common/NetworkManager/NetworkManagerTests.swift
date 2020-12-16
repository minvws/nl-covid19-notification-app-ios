/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest

final class NetworkManagerTests: XCTestCase {

    private var sut: NetworkManager!

    private var mockNetworkConfigurationProvider: NetworkConfigurationProviderMock!
    private var mockNetworkResponseHandlerProvider: NetworkResponseHandlerProviderMock!
    private var mockStorageControlling: StorageControllingMock!
    private var mockUrlSession: URLSessionProtocolMock!
    private var mockUrlSessionDelegate: URLSessionDelegateProtocolMock!
    private var mockUnzipResponseHandler: RxUnzipNetworkResponseHandlerProtocolMock!
    private var mockVerifySignatureResponseHandler: RxVerifySignatureResponseHandlerProtocolMock!
    private var mockReadFromDiskResponseHandler: RxReadFromDiskResponseHandlerProtocolMock!

    override func setUp() {
        super.setUp()

        mockNetworkConfigurationProvider = NetworkConfigurationProviderMock()
        mockNetworkResponseHandlerProvider = NetworkResponseHandlerProviderMock()
        mockStorageControlling = StorageControllingMock()
        mockUrlSession = URLSessionProtocolMock()
        mockUrlSessionDelegate = URLSessionDelegateProtocolMock()
        mockUnzipResponseHandler = RxUnzipNetworkResponseHandlerProtocolMock()
        mockVerifySignatureResponseHandler = RxVerifySignatureResponseHandlerProtocolMock()
        mockReadFromDiskResponseHandler = RxReadFromDiskResponseHandlerProtocolMock()

        mockNetworkResponseHandlerProvider.rxUnzipNetworkResponseHandler = {
            return self.mockUnzipResponseHandler
        }()

        mockNetworkResponseHandlerProvider.rxVerifySignatureResponseHandler = {
            return self.mockVerifySignatureResponseHandler
        }()

        mockNetworkResponseHandlerProvider.rxReadFromDiskResponseHandler = {
            return self.mockReadFromDiskResponseHandler
        }()

        sut = NetworkManager(configurationProvider: mockNetworkConfigurationProvider,
                             responseHandlerProvider: mockNetworkResponseHandlerProvider,
                             storageController: mockStorageControlling,
                             session: mockUrlSession,
                             sessionDelegate: mockUrlSessionDelegate)
    }

    func test_requestFailedShouldReturnError() {
        let mockDataTask = URLSessionDataTaskProtocolMock()
        mockNetworkConfigurationProvider.configuration = .test

        mockUrlSession.resumableDataTaskHandler = { request, completion in
            completion(nil, nil, nil)
            return mockDataTask
        }

        mockDataTask.resumeHandler = {}

        let completionExpectation = expectation(description: "completion")

        sut.getManifest { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_requestSuccessShouldReturnManifest() throws {

        let mockManifest = Manifest(exposureKeySets: ["eks"], riskCalculationParameters: "riskCalculationParameters", appConfig: "appConfig", resourceBundle: "resourceBundle")
        let mockData = try JSONEncoder().encode(mockManifest)

        mockResponseHandlers(readFromDiskData: mockData)

        mockNetworkConfigurationProvider.configuration = .test

        let mockDataTask = URLSessionDataTaskProtocolMock()
        let mockURLResponse = HTTPURLResponse(url: URL(string: "http://someurl.com")!, statusCode: 200, httpVersion: "2", headerFields: nil)
        mockUrlSession.resumableDataTaskHandler = { request, completion in
            completion(mockData, mockURLResponse, nil)
            return mockDataTask
        }

        mockDataTask.resumeHandler = {}

        let completionExpectation = expectation(description: "completion")

        sut.getManifest { result in
            guard case let .success(manifest) = result else {
                XCTFail("Expected success but got error response instead")
                return
            }

            XCTAssertEqual(manifest.appConfig, "appConfig")

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    private func mockResponseHandlers(readFromDiskData: Data) {
        mockUnzipResponseHandler.isApplicableHandler = { _, _ in return true }
        mockUnzipResponseHandler.processHandler = { _, _ in return .just(URL(string: "http://someurl.com")!) }
        mockVerifySignatureResponseHandler.isApplicableHandler = { _, _ in return true }
        mockVerifySignatureResponseHandler.processHandler = { _, _ in return .just(URL(string: "http://someurl.com")!) }
        mockReadFromDiskResponseHandler.isApplicableHandler = { _, _ in return true }
        mockReadFromDiskResponseHandler.processHandler = { _, _ in return .just(readFromDiskData) }
    }
}

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

        mockNetworkConfigurationProvider.configuration = .test

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

    func test_getManifest_requestFailedShouldReturnError() {
        mockUrlSession(mockData: nil)

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

    func test_getManifest_requestSuccessShouldReturnManifest() throws {

        let mockManifest = Manifest(exposureKeySets: ["eks"], riskCalculationParameters: "riskCalculationParameters", appConfig: "appConfig", resourceBundle: "resourceBundle")
        let mockData = try JSONEncoder().encode(mockManifest)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData)

        let completionExpectation = expectation(description: "completion")

        sut.getManifest { result in
            guard case let .success(model) = result else {
                XCTFail("Expected success but got error response instead")
                return
            }

            XCTAssertEqual(model.appConfig, "appConfig")

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getManifest_unzipErrorShouldReturnError() throws {

        let mockManifest = Manifest(exposureKeySets: ["eks"], riskCalculationParameters: "riskCalculationParameters", appConfig: "appConfig", resourceBundle: "resourceBundle")
        let mockData = try JSONEncoder().encode(mockManifest)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateUnzipError: true)

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

    func test_getManifest_validateSignatureErrorShouldReturnError() throws {

        let mockManifest = Manifest(exposureKeySets: ["eks"], riskCalculationParameters: "riskCalculationParameters", appConfig: "appConfig", resourceBundle: "resourceBundle")
        let mockData = try JSONEncoder().encode(mockManifest)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateValidateSignatureError: true)

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

    func test_getManifest_ReadFromDiskErrorShouldReturnError() throws {

        let mockManifest = Manifest(exposureKeySets: ["eks"], riskCalculationParameters: "riskCalculationParameters", appConfig: "appConfig", resourceBundle: "resourceBundle")
        let mockData = try JSONEncoder().encode(mockManifest)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateReadFromDiskError: true)

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

    // MARK: - getAppConfig

    func test_getAppConfig_requestFailedShouldReturnError() {
        mockUrlSession(mockData: nil)

        let completionExpectation = expectation(description: "completion")

        sut.getAppConfig(appConfig: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getAppConfig_requestSuccessShouldReturnManifest() throws {

        let mockModel = AppConfig(version: 1, manifestFrequency: 10, decoyProbability: 2, appStoreURL: "someurl", iOSMinimumVersion: "1.0.0", iOSMinimumVersionMessage: "", iOSAppStoreURL: "", requestMinimumSize: 10, requestMaximumSize: 20, repeatedUploadDelay: nil, coronaMelderDeactivated: nil, appointmentPhoneNumber: nil)
        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData)

        let completionExpectation = expectation(description: "completion")

        sut.getAppConfig(appConfig: "someIdentifier") { result in
            guard case let .success(model) = result else {
                XCTFail("Expected success but got error response instead")
                return
            }

            XCTAssertEqual(model.version, 1)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getAppConfig_unzipErrorShouldReturnError() throws {

        let mockModel = AppConfig(version: 1, manifestFrequency: 10, decoyProbability: 2, appStoreURL: "someurl", iOSMinimumVersion: "1.0.0", iOSMinimumVersionMessage: "", iOSAppStoreURL: "", requestMinimumSize: 10, requestMaximumSize: 20, repeatedUploadDelay: nil, coronaMelderDeactivated: nil, appointmentPhoneNumber: nil)
        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateUnzipError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getAppConfig(appConfig: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getAppConfig_validateSignatureErrorShouldReturnError() throws {

        let mockModel = AppConfig(version: 1, manifestFrequency: 10, decoyProbability: 2, appStoreURL: "someurl", iOSMinimumVersion: "1.0.0", iOSMinimumVersionMessage: "", iOSAppStoreURL: "", requestMinimumSize: 10, requestMaximumSize: 20, repeatedUploadDelay: nil, coronaMelderDeactivated: nil, appointmentPhoneNumber: nil)
        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateValidateSignatureError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getAppConfig(appConfig: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getAppConfig_ReadFromDiskErrorShouldReturnError() throws {

        let mockModel = AppConfig(version: 1, manifestFrequency: 10, decoyProbability: 2, appStoreURL: "someurl", iOSMinimumVersion: "1.0.0", iOSMinimumVersionMessage: "", iOSAppStoreURL: "", requestMinimumSize: 10, requestMaximumSize: 20, repeatedUploadDelay: nil, coronaMelderDeactivated: nil, appointmentPhoneNumber: nil)
        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateReadFromDiskError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getAppConfig(appConfig: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - Private Helper Functions

    private func mockUrlSession(mockData: Data?) {
        let mockDataTask = URLSessionDataTaskProtocolMock()
        mockDataTask.resumeHandler = {}
        let mockURLResponse = HTTPURLResponse(url: URL(string: "http://someurl.com")!, statusCode: 200, httpVersion: "2", headerFields: nil)
        mockUrlSession.resumableDataTaskHandler = { request, completion in
            completion(mockData, mockURLResponse, nil)
            return mockDataTask
        }
    }

    private func mockResponseHandlers(readFromDiskData: Data,
                                      simulateUnzipError: Bool = false,
                                      simulateValidateSignatureError: Bool = false,
                                      simulateReadFromDiskError: Bool = false) {
        mockUnzipResponseHandler.isApplicableHandler = { _, _ in return true }
        mockUnzipResponseHandler.processHandler = { _, _ in
            if simulateUnzipError { return .error(NetworkResponseHandleError.cannotUnzip) }
            else { return .just(URL(string: "http://someurl.com")!) }
        }
        mockVerifySignatureResponseHandler.isApplicableHandler = { _, _ in return true }
        mockVerifySignatureResponseHandler.processHandler = { _, _ in
            if simulateValidateSignatureError { return .error(NetworkResponseHandleError.invalidSignature) }
            else { return .just(URL(string: "http://someurl.com")!) }
        }
        mockReadFromDiskResponseHandler.isApplicableHandler = { _, _ in return true }
        mockReadFromDiskResponseHandler.processHandler = { _, _ in
            if simulateReadFromDiskError { return .error(NetworkResponseHandleError.cannotDeserialize) }
            else { return .just(readFromDiskData) }
        }
    }
}

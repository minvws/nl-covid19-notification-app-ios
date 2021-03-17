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
    private var mockUnzipResponseHandler: UnzipNetworkResponseHandlerProtocolMock!
    private var mockVerifySignatureResponseHandler: VerifySignatureResponseHandlerProtocolMock!
    private var mockReadFromDiskResponseHandler: ReadFromDiskResponseHandlerProtocolMock!

    override func setUp() {
        super.setUp()

        mockNetworkConfigurationProvider = NetworkConfigurationProviderMock()
        mockNetworkResponseHandlerProvider = NetworkResponseHandlerProviderMock()
        mockStorageControlling = StorageControllingMock()
        mockUrlSession = URLSessionProtocolMock()
        mockUrlSessionDelegate = URLSessionDelegateProtocolMock()
        mockUnzipResponseHandler = UnzipNetworkResponseHandlerProtocolMock()
        mockVerifySignatureResponseHandler = VerifySignatureResponseHandlerProtocolMock()
        mockReadFromDiskResponseHandler = ReadFromDiskResponseHandlerProtocolMock()

        mockNetworkConfigurationProvider.configuration = .test

        mockNetworkResponseHandlerProvider.unzipNetworkResponseHandler = {
            return self.mockUnzipResponseHandler
        }()

        mockNetworkResponseHandlerProvider.verifySignatureResponseHandler = {
            return self.mockVerifySignatureResponseHandler
        }()

        mockNetworkResponseHandlerProvider.readFromDiskResponseHandler = {
            return self.mockReadFromDiskResponseHandler
        }()

        sut = NetworkManager(configurationProvider: mockNetworkConfigurationProvider,
                             responseHandlerProvider: mockNetworkResponseHandlerProvider,
                             storageController: mockStorageControlling,
                             session: mockUrlSession,
                             sessionDelegate: mockUrlSessionDelegate)
    }

    // MARK: - getManifest

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

    func test_getManifest_requestSuccessShouldReturnModel() throws {

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

    func test_getAppConfig_requestSuccessShouldReturnModel() throws {

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

    // MARK: - getTreatmentPerspective

    func test_getTreatmentPerspective_requestFailedShouldReturnError() {
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

    func test_getTreatmentPerspective_requestSuccessShouldReturnModel() throws {

        let mockTreatmentPerspective = TreatmentPerspective(resources: ["nl": ["someKey": "someValue"]], guidance: .init(layout: []))
        let mockData = try JSONEncoder().encode(mockTreatmentPerspective)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData)

        let completionExpectation = expectation(description: "completion")

        sut.getTreatmentPerspective(identifier: "someIdentifier") { result in
            guard case let .success(model) = result else {
                XCTFail("Expected success but got error response instead")
                return
            }

            XCTAssertEqual(model.resources["nl"]?["someKey"], "someValue")

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getTreatmentPerspective_unzipErrorShouldReturnError() throws {

        let mockTreatmentPerspective = TreatmentPerspective(resources: ["nl": ["someKey": "someValue"]], guidance: .init(layout: []))
        let mockData = try JSONEncoder().encode(mockTreatmentPerspective)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateUnzipError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getTreatmentPerspective(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getTreatmentPerspective_validateSignatureErrorShouldReturnError() throws {

        let mockTreatmentPerspective = TreatmentPerspective(resources: ["nl": ["someKey": "someValue"]], guidance: .init(layout: []))
        let mockData = try JSONEncoder().encode(mockTreatmentPerspective)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateValidateSignatureError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getTreatmentPerspective(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getTreatmentPerspective_ReadFromDiskErrorShouldReturnError() throws {

        let mockTreatmentPerspective = TreatmentPerspective(resources: ["nl": ["someKey": "someValue"]], guidance: .init(layout: []))
        let mockData = try JSONEncoder().encode(mockTreatmentPerspective)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateReadFromDiskError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getTreatmentPerspective(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - getRiskCalculationParameters

    func test_getRiskCalculationParameters_requestFailedShouldReturnError() {
        mockUrlSession(mockData: nil)

        let completionExpectation = expectation(description: "completion")

        sut.getRiskCalculationParameters(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getRiskCalculationParameters_requestSuccessShouldReturnModel() throws {

        let mockModel = RiskCalculationParameters(minimumRiskScore: 1,
                                                  reportTypeWeights: [7],
                                                  reportTypeWhenMissing: 1,
                                                  infectiousnessWeights: [8],
                                                  attenuationBucketThresholds: [9],
                                                  attenuationBucketWeights: [10],
                                                  daysSinceExposureThreshold: 11,
                                                  minimumWindowScore: 12,
                                                  daysSinceOnsetToInfectiousness: [],
                                                  infectiousnessWhenDaysSinceOnsetMissing: 1)

        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData)

        let completionExpectation = expectation(description: "completion")

        sut.getRiskCalculationParameters(identifier: "someIdentifier") { result in
            guard case let .success(model) = result else {
                XCTFail("Expected success but got error response instead")
                return
            }

            XCTAssertEqual(model.minimumRiskScore, 1)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getRiskCalculationParameters_unzipErrorShouldReturnError() throws {

        let mockData = try JSONEncoder().encode(mockRiskCalculationParameters)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateUnzipError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getRiskCalculationParameters(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    private var mockRiskCalculationParameters: RiskCalculationParameters {
        return RiskCalculationParameters(minimumRiskScore: 1,
                                         reportTypeWeights: [7],
                                         reportTypeWhenMissing: 1,
                                         infectiousnessWeights: [8],
                                         attenuationBucketThresholds: [9],
                                         attenuationBucketWeights: [10],
                                         daysSinceExposureThreshold: 11,
                                         minimumWindowScore: 12,
                                         daysSinceOnsetToInfectiousness: [],
                                         infectiousnessWhenDaysSinceOnsetMissing: 1)
    }

    func test_getRiskCalculationParameters_validateSignatureErrorShouldReturnError() throws {

        let mockData = try JSONEncoder().encode(mockRiskCalculationParameters)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateValidateSignatureError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getRiskCalculationParameters(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getRiskCalculationParameters_ReadFromDiskErrorShouldReturnError() throws {

        let mockData = try JSONEncoder().encode(mockRiskCalculationParameters)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateReadFromDiskError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getRiskCalculationParameters(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - getExposureKeySet

    func test_getExposureKeySet_requestFailedShouldReturnError() {
        mockUrlSession(mockData: nil)

        let completionExpectation = expectation(description: "completion")

        sut.getExposureKeySet(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getExposureKeySet_requestSuccessShouldReturnModel() throws {

        let mockModel = URL(string: "http://someurl.com")
        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData)

        let completionExpectation = expectation(description: "completion")

        sut.getExposureKeySet(identifier: "someIdentifier") { result in
            guard case let .success(model) = result else {
                XCTFail("Expected success but got error response instead")
                return
            }

            XCTAssertEqual(model.absoluteString, "http://someurl.com")

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getExposureKeySet_unzipErrorShouldReturnError() throws {

        let mockModel = URL(string: "http://someurl.com")
        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateUnzipError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getExposureKeySet(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_getExposureKeySet_validateSignatureErrorShouldReturnError() throws {

        let mockModel = URL(string: "http://someurl.com")
        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)
        mockResponseHandlers(readFromDiskData: mockData, simulateValidateSignatureError: true)

        let completionExpectation = expectation(description: "completion")

        sut.getExposureKeySet(identifier: "someIdentifier") { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - postRegister

    func test_postRegister_requestFailedShouldReturnError() {
        mockUrlSession(mockData: nil)

        let completionExpectation = expectation(description: "completion")

        sut.postRegister(request: .init(padding: "000")) { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected error but got successful response instead")
                return
            }

            XCTAssertEqual(error, .invalidResponse)

            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_postRegister_requestSuccessShouldReturnModel() throws {

        let mockModel = LabInformation(labConfirmationId: "labConfirmationId", bucketId: "bucketId", confirmationKey: "confirmationKey", validity: 1)
        let mockData = try JSONEncoder().encode(mockModel)

        mockUrlSession(mockData: mockData)

        let completionExpectation = expectation(description: "completion")

        sut.postRegister(request: .init(padding: "000")) { result in
            guard case let .success(model) = result else {
                XCTFail("Expected success but got error response instead")
                return
            }

            XCTAssertEqual(model.labConfirmationId, "labConfirmationId")

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

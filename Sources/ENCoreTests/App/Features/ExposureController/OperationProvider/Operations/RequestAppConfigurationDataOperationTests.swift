/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import CryptoKit
@testable import ENCore
import Foundation
import XCTest

final class RequestAppConfigurationDataOperationTests: TestCase {
    private var operation: RequestAppConfigurationDataOperation!
    private var appConfigurationIdentifier: String!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!
    private var mockApplicationSignatureController: ApplicationSignatureControllingMock!

    override func setUp() {
        super.setUp()

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()
        mockApplicationSignatureController = ApplicationSignatureControllingMock()

        appConfigurationIdentifier = "test"

        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }

        operation = RequestAppConfigurationDataOperation(networkController: mockNetworkController,
                                                         storageController: mockStorageController,
                                                         applicationSignatureController: mockApplicationSignatureController,
                                                         appConfigurationIdentifier: appConfigurationIdentifier)
    }

    func test_execute_withStoredConfiguration_andCorrectSignature_shouldReturnStoredAppConfiguration() {

        let appConfig = createApplicationConfiguration()

        mockApplicationConfigurationResults(storedConfiguration: appConfig, storedSignature: appConfig.signature, signatureForStoredConfiguration: appConfig.signature)

        let exp = expectation(description: "Completion")

        operation.execute()
            .assertNoFailure()
            .sink { configuration in
                XCTAssertEqual(configuration, appConfig)
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        XCTAssertEqual(mockNetworkController.applicationConfigurationCallCount, 0)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_withStoredConfiguration_andNoSignature_shouldRetrieveFromNetwork() {

        let appConfig = createApplicationConfiguration()
        let networkAppConfig = createApplicationConfiguration(withIdentifier: "appconfig from network")

        mockApplicationConfigurationResults(storedConfiguration: appConfig, networkConfiguration: networkAppConfig, storedSignature: nil)

        let exp = expectation(description: "Completion")

        operation.execute()
            .assertNoFailure()
            .sink { configuration in
                XCTAssertEqual(configuration, networkAppConfig)
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        XCTAssertEqual(mockNetworkController.applicationConfigurationCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_withStoredConfiguration_andNonMatchingIdentifier_shouldRetrieveFromNetwork() {

        let appConfig = createApplicationConfiguration(withIdentifier: "some non matching identifier")
        let networkAppConfig = createApplicationConfiguration(withIdentifier: "appconfig from network")

        mockApplicationConfigurationResults(storedConfiguration: appConfig, networkConfiguration: networkAppConfig, storedSignature: appConfig.signature)

        let exp = expectation(description: "Completion")

        operation.execute()
            .assertNoFailure()
            .sink { configuration in
                XCTAssertEqual(configuration, networkAppConfig)
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        XCTAssertEqual(mockNetworkController.applicationConfigurationCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_withStoredConfiguration_andNonMatchingSignature_shouldRetrieveFromNetwork() {

        let appConfig = createApplicationConfiguration()
        let networkAppConfig = createApplicationConfiguration(withIdentifier: "appconfig from network")

        mockApplicationConfigurationResults(storedConfiguration: appConfig,
                                            networkConfiguration: networkAppConfig,
                                            storedSignature: appConfig.signature,
                                            signatureForStoredConfiguration: "incorrectsignature".data(using: .utf8))

        let exp = expectation(description: "Completion")

        operation.execute()
            .assertNoFailure()
            .sink { configuration in
                XCTAssertEqual(configuration, networkAppConfig)
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        XCTAssertEqual(mockNetworkController.applicationConfigurationCallCount, 1)
        XCTAssertEqual(mockApplicationSignatureController.storeAppConfigurationCallCount, 1)
        XCTAssertEqual(mockApplicationSignatureController.storeSignatureCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_withoutStoredConfiguration_shouldRetrieveFromNetwork() {

        let networkAppConfig = createApplicationConfiguration(withIdentifier: "appconfig from network")

        mockApplicationConfigurationResults(networkConfiguration: networkAppConfig)

        let exp = expectation(description: "Completion")

        operation.execute()
            .assertNoFailure()
            .sink { configuration in
                XCTAssertEqual(configuration, networkAppConfig)
                exp.fulfill()
            }
            .disposeOnTearDown(of: self)

        XCTAssertEqual(mockNetworkController.applicationConfigurationCallCount, 1)
        XCTAssertEqual(mockApplicationSignatureController.storeAppConfigurationCallCount, 1)
        XCTAssertEqual(mockApplicationSignatureController.storeSignatureCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_retrieveFromNetwork_withError_shouldMapExposureDataError() {

        let networkAppConfig = createApplicationConfiguration(withIdentifier: "appconfig from network")

        mockApplicationConfigurationResults(networkConfiguration: networkAppConfig)

        // override networkcontroller call to return an error
        mockNetworkController.applicationConfigurationHandler = { _ in
            Fail(error: NetworkError.invalidRequest).eraseToAnyPublisher()
        }

        let exp = expectation(description: "Completion")

        operation.execute()
            .sink(receiveCompletion: { result in
                guard case let .failure(error) = result,
                    case ExposureDataError.internalError = error else {
                    XCTFail("Call expected to return an error but succeeded instead")
                    return
                }

                exp.fulfill()

            }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(mockNetworkController.applicationConfigurationCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    // MARK: - Helper functions

    private func createApplicationConfiguration(withIdentifier identifier: String = "test") -> ApplicationConfiguration {
        return ApplicationConfiguration(
            version: 0,
            manifestRefreshFrequency: 0,
            decoyProbability: 0,
            creationDate: Date(),
            identifier: identifier,
            minimumVersion: "",
            minimumVersionMessage: "",
            appStoreURL: "",
            requestMinimumSize: 0,
            requestMaximumSize: 0,
            repeatedUploadDelay: 0,
            decativated: false
        )
    }

    /// Helper function to mock stored / network-retrieved application configuration data
    /// - Parameters:
    ///   - storedConfiguration: The configuration that is retrieved from disk (cache)
    ///   - networkConfiguration: The configuration that is retrieved from a network call
    ///   - storedSignature: The signature that is stored on disk. In a non-tampered-with situation this is the signature of `storedConfiguration`)
    ///   - signatureForStoredConfiguration: The signature that should be returned when a signature is created for `storedConfiguration`
    private func mockApplicationConfigurationResults(
        storedConfiguration: ApplicationConfiguration? = nil,
        networkConfiguration: ApplicationConfiguration? = nil,
        storedSignature: Data? = nil,
        signatureForStoredConfiguration: Data? = nil
    ) {
        mockApplicationSignatureController.retrieveStoredConfigurationHandler = { storedConfiguration }
        mockApplicationSignatureController.retrieveStoredSignatureHandler = { storedSignature }
        mockApplicationSignatureController.signatureHandler = { _ in signatureForStoredConfiguration }

        if let networkConfiguration = networkConfiguration {
            mockApplicationSignatureController.storeAppConfigurationHandler = { _ in
                Just(networkConfiguration)
                    .setFailureType(to: ExposureDataError.self)
                    .eraseToAnyPublisher()
            }

            mockApplicationSignatureController.storeSignatureHandler = { _ in
                Just(networkConfiguration)
                    .setFailureType(to: ExposureDataError.self)
                    .eraseToAnyPublisher()
            }

            mockNetworkController.applicationConfigurationHandler = { _ in
                Just(networkConfiguration)
                    .setFailureType(to: NetworkError.self)
                    .eraseToAnyPublisher()
            }
        }
    }
}

private extension ApplicationConfiguration {
    var signature: Data {
        let encoded = try! JSONEncoder().encode(self)
        return SHA256.hash(data: encoded).description.data(using: .utf8)!
    }
}

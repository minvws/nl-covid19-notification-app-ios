/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class ApplicationSignatureControllerTests: TestCase {

    private var sut: ApplicationSignatureController!
    private var mockStorageController: StorageControllingMock!
    private var mockCryptoUtility: CryptoUtilityMock!

    override func setUpWithError() throws {

        mockStorageController = StorageControllingMock()
        mockCryptoUtility = CryptoUtilityMock()

        sut = ApplicationSignatureController(storageController: mockStorageController,
                                             cryptoUtility: mockCryptoUtility)
    }

    func test_retrieveStoredConfiguration() {

        let appConfig = createApplicationConfiguration()
        mockStorageController.retrieveDataHandler = { _ in
            try! JSONEncoder().encode(appConfig)
        }

        let result = sut.retrieveStoredConfiguration()

        XCTAssertEqual(mockStorageController.retrieveDataCallCount, 1)
        XCTAssertEqual(result, appConfig)
    }

    func test_store_withInvalidVersion_shouldReturnError() {

        let appConfig = createApplicationConfiguration(withVersion: 0)

        mockStorageController.retrieveDataHandler = { _ in
            try! JSONEncoder().encode(appConfig)
        }

        let exp = expectation(description: "Completion")
        sut.store(appConfiguration: appConfig).sink { completion in
            guard case let .failure(error) = completion,
                case .serverError = error else {
                XCTFail("Call expected to return an error but succeeded instead")
                return
            }

            exp.fulfill()

        } receiveValue: { _ in
            XCTFail("Unexpected result returned from call that should return an error")
        }
        .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_store_withInvalidManifestRefreshFrequency_shouldReturnError() {

        let appConfig = createApplicationConfiguration(withVersion: 1, manifestRefreshFrequency: 0)

        let exp = expectation(description: "Completion")
        sut.store(appConfiguration: appConfig).sink { completion in
            guard case let .failure(error) = completion,
                case .serverError = error else {
                XCTFail("Call expected to return an error but succeeded instead")
                return
            }

            exp.fulfill()

        } receiveValue: { _ in
            XCTFail("Unexpected result returned from call that should return an error")
        }
        .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_store_shouldCallStorageController() {

        let appConfig = createApplicationConfiguration(withVersion: 1, manifestRefreshFrequency: 1)

        let storageExpectation = expectation(description: "storageCompletion")
        let completionExpectation = expectation(description: "completion")

        mockStorageController.storeHandler = { _, _, completion in
            completion(nil)
            storageExpectation.fulfill()
        }

        sut.store(appConfiguration: appConfig)
            .assertNoFailure()
            .sink(receiveValue: { receivedConfiguration in
                XCTAssertEqual(receivedConfiguration, appConfig)
                completionExpectation.fulfill()
            })
            .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockStorageController.storeCallCount, 1)
    }

    func test_retrieveStoredSignature() throws {

        let signature = "someSignature"

        mockStorageController.retrieveDataHandler = { _ in
            try! JSONEncoder().encode(signature)
        }

        let result = try XCTUnwrap(sut.retrieveStoredSignature())
        let decodedSignature = try XCTUnwrap(JSONDecoder().decode(String.self, from: result))

        XCTAssertEqual(mockStorageController.retrieveDataCallCount, 1)
        XCTAssertEqual(decodedSignature, "someSignature")
    }

    func test_storeSignature_shouldCallStorageController() {

        let appConfig = createApplicationConfiguration(withVersion: 1, manifestRefreshFrequency: 1)

        let storageExpectation = expectation(description: "storageCompletion")
        let completionExpectation = expectation(description: "completion")

        mockCryptoUtility.sha256Handler = { (data: Any) in
            "some hash"
        }

        mockStorageController.storeHandler = { _, _, completion in
            completion(nil)
            storageExpectation.fulfill()
        }

        sut.storeSignature(for: appConfig)
            .assertNoFailure()
            .sink(receiveValue: { receivedConfiguration in
                XCTAssertEqual(receivedConfiguration, appConfig)
                completionExpectation.fulfill()
            })
            .disposeOnTearDown(of: self)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockStorageController.storeCallCount, 1)
    }

    func test_signature() {

        let appConfig = createApplicationConfiguration(withVersion: 1, manifestRefreshFrequency: 1)

        mockCryptoUtility.sha256Handler = { (data: Any) in
            "some hash"
        }

        let signature = sut.signature(for: appConfig)

        XCTAssertEqual(String(data: signature!, encoding: .utf8), "some hash")
    }

    private func createApplicationConfiguration(withVersion version: Int = 0, manifestRefreshFrequency: Int = 0) -> ApplicationConfiguration {
        return ApplicationConfiguration(
            version: version,
            manifestRefreshFrequency: manifestRefreshFrequency,
            decoyProbability: 0,
            creationDate: Date(),
            identifier: "test",
            minimumVersion: "",
            minimumVersionMessage: "",
            appStoreURL: "",
            requestMinimumSize: 0,
            requestMaximumSize: 0,
            repeatedUploadDelay: 0,
            decativated: false,
            testPhase: true
        )
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import RxSwift
import XCTest

final class NetworkControllerTests: TestCase {

    private var networkController: NetworkController!
    private let networkManager = NetworkManagingMock()
    private let cryptoUtility = CryptoUtilityMock()

    override func setUp() {
        super.setUp()

        networkController = NetworkController(networkManager: networkManager,
                                              cryptoUtility: cryptoUtility)
    }

    func test_requestLabConfirmationKey_callsNetworkManager_returnsKeyOnSuccess() {
        networkManager.postRegisterHandler = { _, completion in
            let key = LabInformation(labConfirmationId: "test",
                                     bucketId: "dGVzdA==",
                                     confirmationKey: "dGVzdA==",
                                     validity: 22)

            completion(.success(key))
        }

        var receivedValue: LabConfirmationKey!

        let exp = expectation(description: "wait")

        networkController
            .requestLabConfirmationKey(padding: padding)
            .subscribe(onSuccess: { labConfirmationKey in
                receivedValue = labConfirmationKey
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(receivedValue)
        XCTAssertEqual(receivedValue.identifier, "test")
        XCTAssertEqual(receivedValue.bucketIdentifier, "test".data(using: .utf8))
        XCTAssertEqual(receivedValue.confirmationKey, "test".data(using: .utf8))
        XCTAssertTrue(receivedValue.isValid)
    }

    func test_requestLabConfirmationKey_callsNetworkManager_failsOnInvalidResponse() {
        networkManager.postRegisterHandler = { _, completion in
            completion(.failure(.invalidResponse))
        }

        var receivedValue: LabConfirmationKey!
        var receivedError: Error?

        let exp = expectation(description: "wait")

        networkController
            .requestLabConfirmationKey(padding: padding)
            .subscribe(onSuccess: { labConfirmationKey in
                receivedValue = labConfirmationKey
            }, onFailure: { error in
                receivedError = error
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: 1)

        XCTAssertNil(receivedValue)

        XCTAssertNotNil(receivedError)
        XCTAssertEqual(receivedError as? NetworkError, NetworkError.invalidResponse)
    }

    func test_requestLabConfirmationKey_addsCorrectPadding() {
        networkManager.postRegisterHandler = { request, completion in
            let length = self.requestLength(object: request)
            XCTAssertEqual(length, 1812)
            completion(.failure(.invalidResponse))
        }

        let exp = expectation(description: "wait")

        networkController
            .requestLabConfirmationKey(padding: Padding(minimumRequestSize: 1800, maximumRequestSize: 1800))
            .subscribe(onFailure: { _ in
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: 1)
    }

    func test_requestPostKeys_addsCorrectPadding() {
        networkManager.postKeysHandler = { request, _, completion in
            let length = self.requestLength(object: request)
            XCTAssertEqual(length, 1813)
            completion(nil)
        }

        cryptoUtility.signatureHandler = { _, _ in Data() }

        let exp = expectation(description: "wait")
        let key = LabConfirmationKey(identifier: "", bucketIdentifier: Data(), confirmationKey: Data(), validUntil: currentDate())

        networkController
            .postKeys(keys: [], labConfirmationKey: key, padding: padding)
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_fetchExposureKeySet_shouldCallNetworkManagerWithIdentifier() {
        let identifier = "SomeIdentifier"
        let url = URL(string: "http://www.example.com")!

        let completionExpectation = expectation(description: "completion")
        let networkManagerExpectation = expectation(description: "networkmananger call")

        networkManager.getExposureKeySetHandler = { identifierParameter, completion in
            XCTAssertEqual(identifierParameter, identifier)
            networkManagerExpectation.fulfill()
            completion(.success(url))
        }

        networkController.fetchExposureKeySet(identifier: identifier)
            .subscribe(onSuccess: { result in
                XCTAssertEqual(result.0, identifier)
                XCTAssertEqual(result.1, url)
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertEqual(networkManager.getExposureKeySetCallCount, 1)
    }

    func test_fetchExposureKeySet_callsNetworkManager_failsOnInvalidResponse() {
        let identifier = "SomeIdentifier"
        let expectedError = NetworkError.invalidResponse

        let completionExpectation = expectation(description: "completion")
        let networkManagerExpectation = expectation(description: "networkmananger call")

        networkManager.getExposureKeySetHandler = { _, completion in
            networkManagerExpectation.fulfill()
            completion(.failure(expectedError))
        }

        networkController.fetchExposureKeySet(identifier: identifier)
            .subscribe(onFailure: { error in
                XCTAssertEqual(error as? NetworkError, expectedError)
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertEqual(networkManager.getExposureKeySetCallCount, 1)
    }

    // MARK: - Private

    private let padding = Padding(minimumRequestSize: 1800, maximumRequestSize: 1800)

    private func requestLength<T: Encodable>(object: T) -> Int {
        do {
            return try JSONEncoder().encode(object).count
        } catch {
            return 0
        }
    }
}

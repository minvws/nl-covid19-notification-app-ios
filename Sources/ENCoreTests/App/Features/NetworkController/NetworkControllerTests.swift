/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
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
        var receivedCompletion: Subscribers.Completion<NetworkError>!

        let exp = expectation(description: "wait")

        networkController
            .requestLabConfirmationKey(padding: padding)
            .sink(
                receiveCompletion: { completion in
                    receivedCompletion = completion

                    exp.fulfill()
                },
                receiveValue: { value in
                    receivedValue = value
                })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(receivedValue)
        XCTAssertEqual(receivedValue.identifier, "test")
        XCTAssertEqual(receivedValue.bucketIdentifier, "test".data(using: .utf8))
        XCTAssertEqual(receivedValue.confirmationKey, "test".data(using: .utf8))
        XCTAssertTrue(receivedValue.isValid)

        XCTAssertNotNil(receivedCompletion)
        XCTAssertEqual(receivedCompletion, Subscribers.Completion<NetworkError>.finished)
    }

    func test_requestLabConfirmationKey_callsNetworkManager_failsOnInvalidResponse() {
        networkManager.postRegisterHandler = { _, completion in
            completion(.failure(.invalidResponse))
        }

        var receivedValue: LabConfirmationKey!
        var receivedCompletion: Subscribers.Completion<NetworkError>!

        let exp = expectation(description: "wait")

        networkController
            .requestLabConfirmationKey(padding: padding)
            .sink(
                receiveCompletion: { completion in
                    receivedCompletion = completion

                    exp.fulfill()
                },
                receiveValue: { value in
                    receivedValue = value
                })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)

        XCTAssertNil(receivedValue)

        XCTAssertNotNil(receivedCompletion)
        XCTAssertEqual(receivedCompletion, Subscribers.Completion<NetworkError>.failure(.invalidResponse))
    }

    func test_requestLabConfirmationKey_addsCorrectPadding() {
        networkManager.postRegisterHandler = { request, completion in
            let length = self.requestLength(object: request)
            XCTAssertEqual(length, 1812)
            completion(.failure(.invalidResponse))
        }

        var receivedCompletion: Subscribers.Completion<NetworkError>!

        let exp = expectation(description: "wait")

        networkController
            .requestLabConfirmationKey(padding: Padding(minimumRequestSize: 1800, maximumRequestSize: 1800))
            .sink(receiveCompletion: { completion in
                receivedCompletion = completion
                exp.fulfill()
            },
            receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(receivedCompletion)
    }

    func test_requestPostKeys_addsCorrectPadding() {
        networkManager.postKeysHandler = { request, _, completion in
            let length = self.requestLength(object: request)
            XCTAssertEqual(length, 1813)
            completion(.invalidRequest)
        }

        cryptoUtility.signatureHandler = { _, _ in Data() }

        var receivedCompletion: Subscribers.Completion<NetworkError>!

        let exp = expectation(description: "wait")
        let key = LabConfirmationKey(identifier: "", bucketIdentifier: Data(), confirmationKey: Data(), validUntil: Date())

        networkController
            .postKeys(keys: [], labConfirmationKey: key, padding: padding)
            .sink(receiveCompletion: { completion in
                receivedCompletion = completion
                exp.fulfill()
            },
            receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(receivedCompletion)
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

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
    private let mutableNetworkStatusStream = MutableNetworkStatusStreamingMock()

    override func setUp() {
        super.setUp()

        networkController = NetworkController(networkManager: networkManager,
                                              cryptoUtility: cryptoUtility,
                                              mutableNetworkStatusStream: mutableNetworkStatusStream)
    }

    func test_requestLabConfirmationKey_callsNetworkManager_returnsKeyOnSuccess() {
        networkManager.postRegisterHandler = { _, completion in
            let key = LabInformation(labConfirmationId: "test",
                                     bucketId: "dGVzdA==",
                                     confirmationKey: "dGVzdA==",
                                     validity: 22)

            completion(.success(key))
        }

        cryptoUtility.randomBytesHandler = { _ in return Data() }

        var receivedValue: LabConfirmationKey!
        var receivedCompletion: Subscribers.Completion<NetworkError>!

        let exp = expectation(description: "wait")

        networkController
            .requestLabConfirmationKey()
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

        cryptoUtility.randomBytesHandler = { _ in return Data() }

        var receivedValue: LabConfirmationKey!
        var receivedCompletion: Subscribers.Completion<NetworkError>!

        let exp = expectation(description: "wait")

        networkController
            .requestLabConfirmationKey()
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
}

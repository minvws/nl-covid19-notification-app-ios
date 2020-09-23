/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import XCTest

final class RequestAppConfigurationDataOperationTests: TestCase {
    private var operation: RequestAppConfigurationDataOperation!
    private let networkController = NetworkControllingMock()
    private let storageController = StorageControllingMock()

    override func setUp() {
        super.setUp()

        operation = RequestAppConfigurationDataOperation(networkController: networkController,
                                                         storageController: storageController,
                                                         appConfigurationIdentifier: "test")
    }

    func test_getAppConfig() {

        networkController.applicationConfigurationHandler = { _ in

            let appConfig = ApplicationConfiguration(version: 0,
                                                     manifestRefreshFrequency: 0,
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
                                                     testPhase: true)
            return Just(appConfig)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }

        XCTAssertEqual(networkController.applicationConfigurationCallCount, 0)

        operation.execute()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(networkController.applicationConfigurationCallCount, 1)
    }
}

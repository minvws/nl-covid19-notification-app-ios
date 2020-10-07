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
    private var appConfigurationIdentifier: String!
    private let networkController = NetworkControllingMock()
    private let storageController = StorageControllingMock()

    override func setUp() {
        super.setUp()

        appConfigurationIdentifier = "test"

        storageController.requestExclusiveAccessHandler = { $0(self.storageController) }

        operation = RequestAppConfigurationDataOperation(networkController: networkController,
                                                         storageController: storageController,
                                                         appConfigurationIdentifier: appConfigurationIdentifier)
    }

    func test_getAppConfig() {

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

        storageController.storeHandler = { data, _, completion in

            completion(nil)
        }
    }
}

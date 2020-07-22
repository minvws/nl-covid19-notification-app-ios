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

    // TODO: Write tests
}

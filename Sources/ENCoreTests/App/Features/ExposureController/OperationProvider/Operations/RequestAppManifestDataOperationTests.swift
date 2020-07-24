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

final class RequestAppManifestDataOperationTests: TestCase {
    private var operation: RequestAppManifestDataOperation!
    private let networkController = NetworkControllingMock()
    private let storageController = StorageControllingMock()

    override func setUp() {
        super.setUp()

        operation = RequestAppManifestDataOperation(networkController: networkController,
                                                    storageController: storageController)
    }

    // TODO: Write tests
}

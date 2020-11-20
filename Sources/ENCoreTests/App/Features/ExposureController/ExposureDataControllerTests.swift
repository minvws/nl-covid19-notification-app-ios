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

final class ExposureDataControllerTests: TestCase {
    private var controller: ExposureDataController!
    private let operationProvider = ExposureDataOperationProviderMock()
    private let storageController = StorageControllingMock()

    override func setUp() {
        super.setUp()

        controller = ExposureDataController(operationProvider: operationProvider,
                                            storageController: storageController)
    }

    func test_firstRun_erasesStorage() {
        // These values are incremented during init of `ExposureDataController`,
        // if tests are breaking due to this assert update the call counts accordingly.
        XCTAssertEqual(storageController.storeCallCount, 1)
        XCTAssertEqual(storageController.removeDataCallCount, 3)

        var removedKeys: [StoreKey] = []
        storageController.removeDataHandler = { key, _ in
            removedKeys.append(key as! StoreKey)
        }

        var receivedKey: StoreKey!
        var receivedData: Data!
        storageController.storeHandler = { data, key, _ in
            receivedKey = key as? StoreKey
            receivedData = data
        }

        controller = ExposureDataController(operationProvider: operationProvider,
                                            storageController: storageController)

        XCTAssertEqual(storageController.removeDataCallCount, 6)
        XCTAssertEqual(storageController.storeCallCount, 2)

        let removedKeysStrings = removedKeys.map { $0.asString }
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.labConfirmationKey.asString))
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.lastExposureReport.asString))
        XCTAssert(removedKeysStrings.contains(ExposureDataStorageKey.pendingLabUploadRequests.asString))

        XCTAssertEqual(receivedKey.asString, ExposureDataStorageKey.firstRunIdentifier.asString)
        XCTAssertEqual(receivedData, Data([116, 114, 117, 101])) // true
    }

    func test_subsequentRun_doesNotEraseStorage() {}
}

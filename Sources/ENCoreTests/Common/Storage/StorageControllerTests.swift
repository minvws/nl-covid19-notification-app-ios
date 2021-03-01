/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import XCTest

final class StorageControllerTests: TestCase {

    private var storageControlling: StorageControllingMock!
    private var localPathProvider: LocalPathProvidingMock!
    private var environmentController: EnvironmentControllingMock!
    private var storageController: StorageController!

    override func setUp() {
        super.setUp()

        storageControlling = StorageControllingMock()
        localPathProvider = LocalPathProvidingMock()
        environmentController = EnvironmentControllingMock()

        localPathProvider.pathHandler = { folder in
            if folder == .cache {
                return URL(string: "http://someurl.com")!
            } else if folder == .documents {
                return URL(string: "http://someurl.com")!
            }
            return nil
        }

        storageController = StorageController(localPathProvider: localPathProvider,
                                              environmentController: environmentController)
        storageController.prepareStore()
    }

    func test_prepareStore() {

        XCTAssertEqual(storageControlling.clearPreviouslyStoredVolatileFilesCallCount, 0)

        storageController.storeAvailable = true

        let storeUrl = storageController.storeUrl(isVolatile: false)
        let volatileStoreUrl = storageController.storeUrl(isVolatile: true)

        XCTAssertNotNil(storeUrl)
        XCTAssertNotNil(volatileStoreUrl)

        XCTAssertEqual(directoryExistsAtPath(String(describing: storeUrl)), false)
        XCTAssertEqual(directoryExistsAtPath(String(describing: volatileStoreUrl)), false)

        let exp = expectation(description: "expectation")
        storageControlling.prepareStoreHandler = {
            exp.fulfill()
        }

        storageControlling.prepareStore()

        waitForExpectations(timeout: 1, handler: nil)
    }

    private func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

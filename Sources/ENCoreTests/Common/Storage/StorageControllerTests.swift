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

    private var fileManager: FileManagingMock!
    private var localPathProvider: LocalPathProvidingMock!
    private var environmentController: EnvironmentControllingMock!
    private var storageController: StorageController!

    override func setUp() {
        super.setUp()

        fileManager = FileManagingMock()
        localPathProvider = LocalPathProvidingMock()
        environmentController = EnvironmentControllingMock()

        localPathProvider.temporaryDirectoryUrl = URL(string: "/temp/")!
        localPathProvider.pathHandler = { folder in
            if folder == .documents {
                return URL(string: "/documents/")!
            } else if folder == .cache {
                return URL(string: "/cache/")!
            }
            return nil
        }

        fileManager.urlsHandler = { folder, domainMask in
            return [URL(string: "/folder/folder\(folder.rawValue)")!]
        }

        fileManager.contentsOfDirectoryHandler = { url, _, _ in
            return [url.appendingPathComponent("somefolder")]
        }

        storageController = StorageController(fileManager: fileManager,
                                              localPathProvider: localPathProvider,
                                              environmentController: environmentController)
    }

    func test_prepareStore() {

        let fileManagerExpectation = expectation(description: "filemanager")
        fileManagerExpectation.expectedFulfillmentCount = 2

        XCTAssertEqual(fileManager.createDirectoryCallCount, 0)
        fileManager.createDirectoryHandler = { _, _, _ in
            fileManagerExpectation.fulfill()
        }

        storageController.prepareStore()

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(fileManager.createDirectoryCallCount, 2)
        XCTAssertEqual(fileManager.createDirectoryArgValues.first?.0.absoluteString, "/documents/store")
        XCTAssertTrue(fileManager.createDirectoryArgValues.first?.1 == true)
        XCTAssertEqual(fileManager.createDirectoryArgValues.last?.0.absoluteString, "/cache/store")
        XCTAssertTrue(fileManager.createDirectoryArgValues.last?.1 == true)
    }

    func test_prepareStoreWhenAlreadyAvailable() {

        XCTAssertEqual(fileManager.createDirectoryCallCount, 0)

        storageController.prepareStore()
        storageController.prepareStore()

        XCTAssertEqual(fileManager.createDirectoryCallCount, 2)
    }

    func test_prepareStoreWithCreateDirectoryError() {

        fileManager.createDirectoryHandler = { _, _, _ in
            throw (FileManaging.createDirectoryError)
        }

        storageController.prepareStore()

        XCTAssertEqual(storageController.storeAvailable, false)
    }

    func test_prepareStore_shouldClearTemporaryDirectory() {

        environmentController.isDebugVersion = false
        XCTAssertEqual(fileManager.removeItemCallCount, 0)

        storageController.prepareStore()

        XCTAssertEqual(fileManager.removeItemCallCount, 1)
        XCTAssertEqual(fileManager.removeItemArgValues[0].absoluteString, "/temp/")
    }

    private enum FileManaging: Error {
        case createDirectoryError
    }
}

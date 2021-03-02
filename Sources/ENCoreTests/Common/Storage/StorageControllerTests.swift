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
    private var fileManaging: FileManagingMock!
    private var localPathProvider: LocalPathProvidingMock!
    private var environmentController: EnvironmentControllingMock!
    private var storageController: StorageController!

    override func setUp() {
        super.setUp()

        storageControlling = StorageControllingMock()
        fileManaging = FileManagingMock(manager: FileManager.default)
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

        storageController = StorageController(fileManager: fileManaging,
                                              localPathProvider: localPathProvider,
                                              environmentController: environmentController)
    }

    func test_prepareStore() {

        let storeUrl = storageController.storeUrl(isVolatile: false)
        let volatileStoreUrl = storageController.storeUrl(isVolatile: true)

        XCTAssertNotNil(storeUrl)
        XCTAssertNotNil(volatileStoreUrl)

        XCTAssertEqual(directoryExistsAtPath(String(describing: storeUrl)), false)
        XCTAssertEqual(directoryExistsAtPath(String(describing: volatileStoreUrl)), false)

        let exp = expectation(description: "exp")
        var count = 0
        fileManaging.createDirectoryAtHandler = { _, _ in
            count += 1
            if count == 2 {
                exp.fulfill()
            }
        }

        storageController.prepareStore()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_prepareStoreWhenAlreadyAvailable() {

        storageController.storeAvailable = true
        storageController.prepareStore()
        XCTAssertEqual(fileManaging.createDirectoryAtCallCount, 0)
    }

    func test_prepareStoreWithCreateDirectoryError() {

        let storeUrl = storageController.storeUrl(isVolatile: false)
        let volatileStoreUrl = storageController.storeUrl(isVolatile: true)

        XCTAssertNotNil(storeUrl)
        XCTAssertNotNil(volatileStoreUrl)

        XCTAssertEqual(directoryExistsAtPath(String(describing: storeUrl)), false)
        XCTAssertEqual(directoryExistsAtPath(String(describing: volatileStoreUrl)), false)

        fileManaging.createDirectoryAtHandler = { _, _ in
            throw (FileManaging.createDirectoryError)
        }

        storageController.prepareStore()

        XCTAssertEqual(storageController.storeAvailable, false)
    }

    func test_prepareStoreClearPreviouslyStoredVolatileFiles() {

        let exp = expectation(description: "exp")
        storageControlling.clearPreviouslyStoredVolatileFilesHandler = {
            exp.fulfill()
        }

        XCTAssertEqual(storageControlling.clearPreviouslyStoredVolatileFilesCallCount, 0)
        storageControlling.clearPreviouslyStoredVolatileFiles()
        XCTAssertEqual(storageControlling.clearPreviouslyStoredVolatileFilesCallCount, 1)

        waitForExpectations(timeout: 2, handler: nil)
    }

    private func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = fileManaging.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private enum FileManaging: Error {
        case createDirectoryError
    }
}

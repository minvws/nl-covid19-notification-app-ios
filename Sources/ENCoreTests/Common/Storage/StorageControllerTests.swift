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

    private var sut: StorageController!
    private var mockFileManager: FileManagingMock!
    private var mockLocalPathProvider: LocalPathProvidingMock!
    private var mockEnvironmentController: EnvironmentControllingMock!
    private var mockDataAccessor: DataAccessingMock!

    override func setUp() {
        super.setUp()

        mockFileManager = FileManagingMock()
        mockLocalPathProvider = LocalPathProvidingMock()
        mockEnvironmentController = EnvironmentControllingMock()
        mockDataAccessor = DataAccessingMock()

        mockLocalPathProvider.temporaryDirectoryUrl = URL(string: "/temp/")!
        mockLocalPathProvider.pathHandler = { folder in
            if folder == .documents {
                return URL(string: "/documents/")!
            } else if folder == .cache {
                return URL(string: "/cache/")!
            }
            return nil
        }

        mockFileManager.urlsHandler = { folder, domainMask in
            return [URL(string: "/folder/folder\(folder.rawValue)")!]
        }

        mockFileManager.contentsOfDirectoryHandler = { url, _, _ in
            return [url.appendingPathComponent("somefolder")]
        }

        sut = StorageController(fileManager: mockFileManager,
                                localPathProvider: mockLocalPathProvider,
                                environmentController: mockEnvironmentController,
                                dataAccessor: mockDataAccessor)
    }

    func test_prepareStore() {

        let fileManagerExpectation = expectation(description: "filemanager")
        fileManagerExpectation.expectedFulfillmentCount = 2

        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 0)
        mockFileManager.createDirectoryHandler = { _, _, _ in
            fileManagerExpectation.fulfill()
        }

        sut.prepareStore()

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 2)
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.0.absoluteString, "/documents/store")
        XCTAssertTrue(mockFileManager.createDirectoryArgValues.first?.1 == true)
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.last?.0.absoluteString, "/cache/store")
        XCTAssertTrue(mockFileManager.createDirectoryArgValues.last?.1 == true)
    }

    func test_prepareStoreWhenAlreadyAvailable() {

        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 0)

        sut.prepareStore()
        sut.prepareStore()

        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 2)
    }

    func test_prepareStoreWithCreateDirectoryError() {

        mockFileManager.createDirectoryHandler = { _, _, _ in
            throw (FileManaging.createDirectoryError)
        }

        sut.prepareStore()

        XCTAssertEqual(sut.storeAvailable, false)
    }

    func test_prepareStore_shouldClearTemporaryDirectory() {

        mockEnvironmentController.isDebugVersion = false
        XCTAssertEqual(mockFileManager.removeItemCallCount, 0)

        sut.prepareStore()

        XCTAssertEqual(mockFileManager.removeItemCallCount, 1)
        XCTAssertEqual(mockFileManager.removeItemArgValues[0].absoluteString, "/temp/")
    }

    func test_store() throws {
        // Arrange
        sut.prepareStore()

        let storeCompletionExpectation = expectation(description: "storeCompletionExpectation")
        let testStorageKey = StorageKey(name: "test", storeType: .insecure(volatile: false, maximumAge: 20))
        let data = "some string".data(using: .utf8)!

        // Act
        sut.store(data: data, identifiedBy: testStorageKey) { error in
            XCTAssertNil(error)
            storeCompletionExpectation.fulfill()
        }

        // Assert
        waitForExpectations()
        XCTAssertEqual(mockDataAccessor.writeCallCount, 1)
        XCTAssertEqual(mockDataAccessor.writeArgValues.first?.0, data)
        XCTAssertEqual(mockDataAccessor.writeArgValues.first?.1.absoluteString, "/documents/store/test")
    }

    func test_retrieve() throws {
        // Arrange
        sut.prepareStore()
        mockFileManager.fileExistsHandler = { _, _ in return true }
        mockDataAccessor.readHandler = { url in return "some string".data(using: .utf8) }
        let testStorageKey = StorageKey(name: "test", storeType: .insecure(volatile: false, maximumAge: 20))

        // Act
        let retrievedData = try XCTUnwrap(sut.retrieveData(identifiedBy: testStorageKey))

        // Assert
        XCTAssertEqual(mockDataAccessor.readCallCount, 1)
        XCTAssertEqual(mockDataAccessor.readArgValues.first?.absoluteString, "/documents/store/test")
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/documents/store/test")

        let retrievedString = String(data: retrievedData, encoding: .utf8)
        XCTAssertEqual(retrievedString, "some string")
    }

    func test_retrieve_passedMaximumAge() throws {
        // Arrange
        let date = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        DateTimeTestingOverrides.overriddenCurrentDate = date

        sut.prepareStore()
        mockFileManager.attributesOfItemHandler = { path in [.modificationDate: date.addingTimeInterval(-1000)] }
        let testStorageKey = StorageKey(name: "test", storeType: .insecure(volatile: false, maximumAge: 20))

        // Act
        let retrievedData = sut.retrieveData(identifiedBy: testStorageKey)

        // Assert
        XCTAssertNil(retrievedData)
        XCTAssertEqual(mockFileManager.attributesOfItemCallCount, 1)
        XCTAssertEqual(mockFileManager.attributesOfItemArgValues.first, "/documents/store/test")
    }

    func test_removeData() {
        // Arrange
        sut.prepareStore()
        let completionExpectation = expectation(description: "completionExpectation")
        let testStorageKey = StorageKey(name: "test", storeType: .insecure(volatile: false, maximumAge: 20))

        // Mock existing data
        mockFileManager.fileExistsHandler = { _, _ in return true }
        mockDataAccessor.readHandler = { url in return "some string".data(using: .utf8) }

        XCTAssertEqual(mockFileManager.removeItemCallCount, 1)

        // Act
        sut.removeData(for: testStorageKey) { error in
            XCTAssertNil(error)
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations()

        XCTAssertEqual(mockFileManager.removeItemCallCount, 2)
        XCTAssertEqual(mockFileManager.removeItemArgValues.first?.absoluteString, "/temp/")
        XCTAssertEqual(mockFileManager.removeItemArgValues.last?.absoluteString, "/documents/store/test")
    }

    private enum FileManaging: Error {
        case createDirectoryError
    }
}

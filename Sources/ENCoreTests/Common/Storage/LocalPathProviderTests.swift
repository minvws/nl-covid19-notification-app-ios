/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class LocalPathProviderTests: TestCase {

    private var mockFileManager: FileManagingMock!
    private var sut: LocalPathProvider!

    override func setUpWithError() throws {
        mockFileManager = FileManagingMock()
        sut = LocalPathProvider(fileManager: mockFileManager)
    }

    func test_path_cache() {
        // Arrange
        let url = URL(string: "http://www.someurl.com")!
        mockFileManager.urlsHandler = { directory, domainMask in
            XCTAssertEqual(directory, .cachesDirectory)
            XCTAssertEqual(domainMask, .userDomainMask)
            return [url]
        }

        // Act
        let result = sut.path(for: .cache)

        // Assert
        XCTAssertEqual(result, url)
        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 1)
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.0.absoluteString, "http://www.someurl.com")
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.1, true)
    }

    func test_path_documents() {
        // Arrange
        let url = URL(string: "http://www.someurl.com")!
        mockFileManager.urlsHandler = { directory, domainMask in
            XCTAssertEqual(directory, .documentDirectory)
            XCTAssertEqual(domainMask, .userDomainMask)
            return [url]
        }

        // Act
        let result = sut.path(for: .documents)

        // Assert
        XCTAssertEqual(result, url)
        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 1)
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.0.absoluteString, "http://www.someurl.com")
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.1, true)
    }

    func test_path_temporary() {
        // Arrange
        let url = URL(string: "http://www.someurl.com")!
        mockFileManager.urlsHandler = { directory, domainMask in
            XCTAssertEqual(directory, .itemReplacementDirectory)
            XCTAssertEqual(domainMask, .userDomainMask)
            return [url]
        }

        // Act
        let result = sut.path(for: .temporary)

        // Assert
        XCTAssertEqual(result, url)
        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 1)
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.0.absoluteString, "http://www.someurl.com")
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.1, true)
    }

    func test_path_exposureKeySets() {
        // Arrange
        let url = URL(string: "http://www.someurl.com")!
        mockFileManager.urlsHandler = { directory, domainMask in
            XCTAssertEqual(directory, .documentDirectory)
            XCTAssertEqual(domainMask, .userDomainMask)
            return [url]
        }

        // Act
        let result = sut.path(for: .exposureKeySets)

        // Assert
        XCTAssertEqual(result, URL(string: "http://www.someurl.com/exposureKeySets")!)
        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 2)
    }

    func test_path_withFailingDirectoryCreation_shouldReturnNil() {
        // Arrange
        let url = URL(string: "http://www.someurl.com")!
        mockFileManager.urlsHandler = { directory, domainMask in
            XCTAssertEqual(directory, .documentDirectory)
            XCTAssertEqual(domainMask, .userDomainMask)
            return [url]
        }

        mockFileManager.createDirectoryHandler = { _, _, _ in
            throw TestError.someError
        }

        // Act
        let result = sut.path(for: .exposureKeySets)

        // Assert
        XCTAssertEqual(result, nil)
        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 1)
    }

    private enum TestError: Error {
        case someError
    }
}

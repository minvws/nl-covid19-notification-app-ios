/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class ReadFromDiskResponseHandlerTests: TestCase {

    private var sut: ReadFromDiskResponseHandler!
    private var mockFileManager: FileManagingMock!

    override func setUpWithError() throws {
        mockFileManager = FileManagingMock()
        sut = ReadFromDiskResponseHandler(fileManager: mockFileManager)
    }

    func test_isApplicable_withValidFolderURL() {
        // Arrange
        let urlResponse = URLResponse()
        let input = URL(string: "/someurl/")!
        mockFileManager.fileExistsHandler = { _, isDirectory in
            isDirectory?.pointee = true
            return true
        }
        mockFileManager.fileExistsAtPathHandler = { _ in true }

        // Act
        let result = sut.isApplicable(for: urlResponse, input: input)

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/someurl")
        XCTAssertEqual(mockFileManager.fileExistsAtPathCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsAtPathArgValues.first, "/someurl/content.bin")
    }

    func test_isApplicable_withNonExistingFolder() {
        // Arrange
        let urlResponse = URLResponse()
        let input = URL(string: "/someurl/")!
        mockFileManager.fileExistsHandler = { _, isDirectory in
            isDirectory?.pointee = true
            return false
        }
        mockFileManager.fileExistsAtPathHandler = { _ in true }

        // Act
        let result = sut.isApplicable(for: urlResponse, input: input)

        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/someurl")
        XCTAssertEqual(mockFileManager.fileExistsAtPathCallCount, 0)
    }

    func test_isApplicable_withNonExistingContentFile() {
        // Arrange
        let urlResponse = URLResponse()
        let input = URL(string: "/someurl/")!
        mockFileManager.fileExistsHandler = { _, isDirectory in
            isDirectory?.pointee = true
            return true
        }
        mockFileManager.fileExistsAtPathHandler = { _ in false }

        // Act
        let result = sut.isApplicable(for: urlResponse, input: input)

        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/someurl")
        XCTAssertEqual(mockFileManager.fileExistsAtPathCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsAtPathArgValues.first, "/someurl/content.bin")
    }

    func test_isApplicable_withDirectContentURL() {
        // Arrange
        let urlResponse = URLResponse()
        let input = URL(string: "/someurl/content.bin")!
        mockFileManager.fileExistsHandler = { _, isDirectory in
            isDirectory?.pointee = false
            return true
        }
        mockFileManager.fileExistsAtPathHandler = { _ in true }

        // Act
        let result = sut.isApplicable(for: urlResponse, input: input)

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/someurl/content.bin")
        XCTAssertEqual(mockFileManager.fileExistsAtPathCallCount, 0)
    }

    func test_process_withInvalidInputURL() {
        // Arrange
        let urlResponse = URLResponse()
        let input = URL(fileURLWithPath: Bundle(for: Self.self).path(forResource: "content", ofType: "bin")!)
        let completionExpectation = expectation(description: "completionExpectation")
        mockFileManager.fileExistsHandler = { _, _ in false }

        // Act
        sut.process(response: urlResponse, input: input)
            .subscribe(onFailure: { error in
                XCTAssertTrue(error is NetworkResponseHandleError)
                XCTAssertEqual(error as? NetworkResponseHandleError, NetworkResponseHandleError.cannotDeserialize)
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations()

        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsAtPathCallCount, 0)
    }

    func test_process_withValidInputURL() {
        // Arrange
        let urlResponse = URLResponse()
        let input = URL(fileURLWithPath: Bundle(for: Self.self).path(forResource: "content", ofType: "bin")!)
        let completionExpectation = expectation(description: "completionExpectation")
        mockFileManager.fileExistsHandler = { _, _ in true }

        // Act
        sut.process(response: urlResponse, input: input)
            .subscribe(onSuccess: { _ in
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations()

        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsAtPathCallCount, 0)
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class UnzipNetworkResponseHandlerTests: TestCase {

    private var sut: UnzipNetworkResponseHandler!
    private var mockFileManager: FileManagingMock!
    private var mockLocalPathProvider: LocalPathProvidingMock!

    override func setUpWithError() throws {
        mockFileManager = FileManagingMock()
        mockLocalPathProvider = LocalPathProvidingMock()
        sut = UnzipNetworkResponseHandler(
            fileManager: mockFileManager,
            localPathProvider: mockLocalPathProvider)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_isApplicable() {
        // Arrange
        let urlResponse = URLResponseProtocolMock()
        urlResponse.contentType = HTTPContentType.zip.rawValue
        let input = URL(string: "http://someurl.com")!

        // Act
        let result = sut.isApplicable(for: urlResponse, input: input)

        // Assert
        XCTAssertTrue(result)
    }

    func test_isApplicable_withUppercasedContentType() {
        // Arrange
        let urlResponse = URLResponseProtocolMock()
        urlResponse.contentType = "Application/Zip"
        let input = URL(string: "http://someurl.com")!

        // Act
        let result = sut.isApplicable(for: urlResponse, input: input)

        // Assert
        XCTAssertTrue(result)
    }

    func test_isApplicable_withNonZipContent() {
        // Arrange
        let urlResponse = URLResponseProtocolMock()
        urlResponse.contentType = HTTPContentType.json.rawValue
        let input = URL(string: "http://someurl.com")!

        // Act
        let result = sut.isApplicable(for: urlResponse, input: input)

        // Assert
        XCTAssertFalse(result)
    }

    func test_process() {
        // Arrange
        let input = URL(string: "http://someurl.com")!
        let urlResponse = URLResponseProtocolMock()
        mockLocalPathProvider.temporaryDirectoryUrl = URL(string: "/temp")!
        mockFileManager.generateRandomUUIDFileNameHandler = { return "random-file-name" }
        let completionExpectation = expectation(description: "completion")

        // Act
        sut.process(response: urlResponse, input: input)
            .subscribe { _ in
                completionExpectation.fulfill()
            }
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations()

        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 1)
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.0.absoluteString, "/temp/random-file-name")
        XCTAssertEqual(mockFileManager.createDirectoryArgValues.first?.1, true)

        XCTAssertEqual(mockFileManager.unzipItemCallCount, 1)
        XCTAssertEqual(mockFileManager.unzipItemArgValues.first?.0.absoluteString, "http://someurl.com")
        XCTAssertEqual(mockFileManager.unzipItemArgValues.first?.1.absoluteString, "/temp/random-file-name")
    }

    func test_process_withError() {
        // Arrange
        let input = URL(string: "http://someurl.com")!
        let urlResponse = URLResponseProtocolMock()
        mockLocalPathProvider.temporaryDirectoryUrl = URL(string: "/temp")!
        mockFileManager.generateRandomUUIDFileNameHandler = { return "random-file-name" }
        mockFileManager.createDirectoryHandler = { _, _, _ in throw NSError(domain: "somedomain", code: 1, userInfo: nil) }

        let completionExpectation = expectation(description: "completion")

        // Act
        sut.process(response: urlResponse, input: input)
            .subscribe(onFailure: { error in
                XCTAssertTrue(error is NetworkResponseHandleError)
                XCTAssertEqual(error as? NetworkResponseHandleError, .cannotUnzip)
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // Assert
        waitForExpectations()
    }
}

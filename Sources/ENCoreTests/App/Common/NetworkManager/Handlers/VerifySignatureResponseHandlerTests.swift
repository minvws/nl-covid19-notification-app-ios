/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import ENCore

class VerifySignatureResponseHandlerTests: TestCase {
    
    private var sut: VerifySignatureResponseHandler!
    private var mockCryptoUtility: CryptoUtilityMock!
    private var mockFileManager: FileManagingMock!
    
    override func setUpWithError() throws {
        mockCryptoUtility = CryptoUtilityMock()
        mockFileManager = FileManagingMock()
        
        // Default mock handlers
        mockFileManager.fileExistsHandler = { _, _ in
            true
        }
        
        mockCryptoUtility.validateHandler = { _, _ ,completion in
            completion(true)
        }
        
        sut = VerifySignatureResponseHandler(
            cryptoUtility: mockCryptoUtility,
            fileManager: mockFileManager
        )
    }
    
    func test_isApplicable_shouldReturnTrue() {
        // Arrange
        let response = URLResponseProtocolMock()
        let url = URL(string: "http://www.someurl.com")!
        
        // Act
        let result = sut.isApplicable(for: response, input: url)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_process_folderURLShouldReturnError() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        
        mockFileManager.fileExistsHandler = { _, isDirectory in
            isDirectory?.pointee = true
            return true
        }
        
        let response = URLResponseProtocolMock()
        let url = URL(string: "/some/file/url")!
        
        // Act
        sut.process(response: response, input: url)
            .subscribe(onFailure: { (error) in
                if case NetworkResponseHandleError.invalidSignature = error {
                    completionExpectation.fulfill()
                } else {
                    XCTFail("unexpected error message")
                }
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations()
        
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/some/file/url/content.sig")
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
    }
    
    func test_process_missingSignatureShouldReturnError() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        
        mockFileManager.fileExistsHandler = { _, isDirectory in
            return false
        }
        
        let response = URLResponseProtocolMock()
        let url = URL(string: "/some/file/url")!
        
        // Act
        sut.process(response: response, input: url)
            .subscribe(onFailure: { (error) in
                if case NetworkResponseHandleError.invalidSignature = error {
                    completionExpectation.fulfill()
                } else {
                    XCTFail("unexpected error message")
                }
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations()
        
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/some/file/url/content.sig")
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 1)
    }
    
    func test_process_shouldCheckSignatureFileName() {
        // Arrange
        let response = URLResponseProtocolMock()
        let url = URL(string: "/some/file/url")!
        
        // Act
        sut.process(response: response, input: url)
            .subscribe()
            .disposed(by: disposeBag)
        
        // Assert
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/some/file/url/content.sig")
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 2)
    }
    
    func test_process_shouldCheckContentFileName() {
        // Arrange
        let response = URLResponseProtocolMock()
        let url = URL(string: "/some/file/url")!
        
        // signature should exist
        mockFileManager.fileExistsHandler = { path, _ in
            path.contains("content.sig")
        }
        
        // Act
        sut.process(response: response, input: url)
            .subscribe()
            .disposed(by: disposeBag)
        
        // Assert
        XCTAssertEqual(mockFileManager.fileExistsArgValues.first?.0, "/some/file/url/content.sig")
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 3)
    }
    
    func test_process_shouldCheckTekFilename() {
        // Arrange
        let response = URLResponseProtocolMock()
        let url = URL(string: "/some/file/url")!
        
        // signature should exist, content file should not
        mockFileManager.fileExistsHandler = { path, _ in
            path.contains("content.sig")
        }
        
        // Act
        sut.process(response: response, input: url)
            .subscribe()
            .disposed(by: disposeBag)
        
        // Assert
        XCTAssertEqual(mockFileManager.fileExistsArgValues.last?.0, "/some/file/url/export.bin")
        XCTAssertEqual(mockFileManager.fileExistsCallCount, 3)
    }
    
    func test_process_shouldValidateSignature() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        let response = URLResponseProtocolMock()
        let url = Bundle(for: SignatureValidatorTests.self).resourceURL!
        
        // Act
        sut.process(response: response, input: url)
            .subscribe(onSuccess: { (_) in
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockCryptoUtility.validateCallCount, 1)
    }
    
    func test_process_invalidSignatureShouldReturnError() {
        // Arrange
        let completionExpectation = expectation(description: "completion")
        let response = URLResponseProtocolMock()
        let url = Bundle(for: SignatureValidatorTests.self).resourceURL!
        
        mockCryptoUtility.validateHandler = { _, _ ,completion in
            completion(false)
        }
        
        // Act
        sut.process(response: response, input: url)
            .subscribe(onFailure: { (error) in
                if case NetworkResponseHandleError.invalidSignature = error {
                    completionExpectation.fulfill()
                } else {
                    XCTFail("unexpected error message")
                }
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockCryptoUtility.validateCallCount, 1)
    }
}

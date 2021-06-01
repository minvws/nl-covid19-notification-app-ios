/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import XCTest
import ENFoundation

final class KeySetDownloadProcessorTests: TestCase {

    private var sut: KeySetDownloadProcessor!

    private var mockStorageController: StorageControllingMock!
    private var mockLocalPathProvider: LocalPathProvidingMock!
    private var mockFileManager: FileManagingMock!

    private var storedKeySetHolders = [ExposureKeySetHolder]()
    
    override func setUp() {
        super.setUp()

        mockStorageController = StorageControllingMock()
        mockLocalPathProvider = LocalPathProvidingMock()
        mockFileManager = FileManagingMock()

        mockLocalPathProvider.pathHandler = { _ in URL(string: "//some/local/path")! }
        mockFileManager.removeItemAtPathHandler = { _ in }
        mockFileManager.fileExistsAtPathHandler = { _ in return false }
        mockStorageController.requestExclusiveAccessHandler = { completion in completion(self.mockStorageController) }
        
        mockStorageController.storeHandler = { object, key, completion in
            guard (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString else {
                completion(nil)
                return
            }
            
            self.storedKeySetHolders = try! JSONDecoder().decode([ExposureKeySetHolder].self, from: object)
            completion(nil)
        }
        
        sut = KeySetDownloadProcessor(storageController: mockStorageController,
                                      localPathProvider: mockLocalPathProvider,
                                      fileManager: mockFileManager)
    }

    func test_process_shouldStoreKeySetHolder() throws {
        // Arrange
        let date = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        DateTimeTestingOverrides.overriddenCurrentDate = date
        
        let identifier = "identifier"
        let url = URL(string: "//some/local/temporary/url")!
        
        let completionExpectation = expectation(description: "completion")
        
        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString {
                return try! JSONEncoder().encode([self.dummyKeySetHolder(withIdentifier: "existingKeySetHolder")])
            }

            return nil
        }
        
        XCTAssertEqual(mockStorageController.requestExclusiveAccessCallCount, 0)
        XCTAssertEqual(storedKeySetHolders.count, 0)
        
        // Act
        sut.process(identifier: identifier, url: url)
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockStorageController.requestExclusiveAccessCallCount, 1)
        XCTAssertEqual(storedKeySetHolders.count, 2)
        XCTAssertEqual(storedKeySetHolders.first?.identifier, "existingKeySetHolder")
        
        let storedKeySet = try XCTUnwrap(storedKeySetHolders.last)
        XCTAssertEqual(storedKeySet.identifier, identifier)
        XCTAssertEqual(storedKeySet.binaryFilename, "identifier.bin")
        XCTAssertEqual(storedKeySet.signatureFilename, "identifier.sig")
        XCTAssertEqual(storedKeySet.creationDate, date)
        XCTAssertNil(storedKeySet.processDate)
        XCTAssertFalse(storedKeySet.processed)
    }
    
    func test_process_shouldReturnErrorIfLocalKeySetPathCannotBeFound() {
        // Arrange
        let identifier = "identifier"
        let url = URL(string: "//some/local/temporary/url")!
        
        let completionExpectation = expectation(description: "completion")
        
        mockLocalPathProvider.pathHandler = { _ in
            return nil
        }
        
        // Act
        sut.process(identifier: identifier, url: url)
            .subscribe(onError: { error in
                XCTAssertEqual(error as? ExposureDataError, ExposureDataError.internalError)
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockLocalPathProvider.pathCallCount, 1)
    }
    
    func test_process_shouldRemoveFilesIfTheyAlreadyExist() {
        // Arrange
        let identifier = "identifier"
        let url = URL(string: "//some/local/temporary/url")!
        
        let completionExpectation = expectation(description: "completion")
        
        mockFileManager.fileExistsAtPathHandler = { _ in return true }
                
        // Act
        sut.process(identifier: identifier, url: url)
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockFileManager.fileExistsAtPathArgValues, ["/local/path/identifier.sig", "/local/path/identifier.bin"])
        XCTAssertEqual(mockFileManager.removeItemAtPathArgValues, ["/local/path/identifier.sig", "/local/path/identifier.bin"])
    }
    
    func test_process_shouldMoveFilesOutOfTemporaryFolder() {
        // Arrange
        let identifier = "identifier"
        let url = URL(string: "//some/local/temporary/url")!
        
        let completionExpectation = expectation(description: "completion")
        
        // Act
        sut.process(identifier: identifier, url: url)
            .subscribe(onCompleted: {
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
        
        XCTAssertEqual(mockFileManager.moveItemArgValues.first?.0.absoluteString, "//some/local/temporary/url/export.sig")
        XCTAssertEqual(mockFileManager.moveItemArgValues.first?.1.absoluteString, "//some/local/path/identifier.sig")
        XCTAssertEqual(mockFileManager.moveItemArgValues.last?.0.absoluteString, "//some/local/temporary/url/export.bin")
        XCTAssertEqual(mockFileManager.moveItemArgValues.last?.1.absoluteString, "//some/local/path/identifier.bin")
    }
    
    // MARK: - Private helper functions
    
    private func dummyKeySetHolder(withIdentifier identifier: String = "identifier") -> ExposureKeySetHolder {
        ExposureKeySetHolder(identifier: identifier, signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate())
    }
}

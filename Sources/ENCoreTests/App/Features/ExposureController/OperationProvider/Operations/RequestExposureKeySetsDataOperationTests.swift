/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import XCTest

class RequestExposureKeySetsDataOperationTests: TestCase {

    private var sut: RequestExposureKeySetsDataOperation!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!
    private var mockLocalPathProvider: LocalPathProvidingMock!
    private var mockFileManager: FileManagingMock!
    private var exposureKeySetIdentifiers: [String]!
    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()
        mockLocalPathProvider = LocalPathProvidingMock()
        mockFileManager = FileManagingMock()
        exposureKeySetIdentifiers = ["identifier"]

        // Default handlers
        mockFileManager.fileExistsHandler = { _, _ in true }
        mockNetworkController.fetchExposureKeySetHandler = { identifier in
            return .just((identifier, URL(string: "http://someurl.com")!))
        }
        mockLocalPathProvider.pathHandler = { localFolder in
            return URL(string: "http://someurl.com")!
        }
        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }
        mockStorageController.storeHandler = { object, identifiedBy, completion in
            completion(nil)
        }

        sut = RequestExposureKeySetsDataOperation(
            networkController: mockNetworkController,
            storageController: mockStorageController,
            localPathProvider: mockLocalPathProvider,
            exposureKeySetIdentifiers: exposureKeySetIdentifiers,
            fileManager: mockFileManager
        )
    }

    func test_shouldNotDownloadKeySetsIfAllIdentifiersAreStoredAlready() {

        let exp = expectation(description: "expectation")

        // `identifier` matches stored keysetidentifier
        mockStorage(storedKeySetHolders: [dummyKeySetHolder()])

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockNetworkController.fetchExposureKeySetCallCount, 0)
    }

    func test_shouldDownloadKeySets() {

        let exp = expectation(description: "expectation")

        // `identifier` matches stored keysetidentifier
        mockStorage(
            storedKeySetHolders: [dummyKeySetHolder(withIdentifier: "SomeOldIdentifier")],
            initialKeySetsIgnored: true // Act as if the initial keyset was already ignored
        )

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockNetworkController.fetchExposureKeySetCallCount, 1)
    }

    func test_execute_fetchExposureKeySet_withError_shouldMapExposureDataError() {

        mockStorage(
            storedKeySetHolders: [dummyKeySetHolder(withIdentifier: "SomeOldIdentifier")],
            initialKeySetsIgnored: true // Act as if the initial keyset was already ignored
        )

        mockNetworkController.fetchExposureKeySetHandler = { _ in
            return .error(ExposureDataError.internalError)
        }

        let exp = expectation(description: "Completion")
        _ = sut.execute()
            .subscribe(onError: { error in
                XCTAssertEqual(error as? ExposureDataError, ExposureDataError.internalError)
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(mockNetworkController.fetchExposureKeySetCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_retrieveObject_withNil() {

        mockStorageController.retrieveDataHandler = { _ in
            return nil
        }

        let exp = expectation(description: "Completion")

        _ = sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(mockStorageController.retrieveDataCallCount, 3)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_createKeySetHolder_withError_shouldMapExposureDataError() {

        mockStorage(
            storedKeySetHolders: [dummyKeySetHolder(withIdentifier: "SomeOldIdentifier")],
            initialKeySetsIgnored: true // Act as if the initial keyset was already ignored
        )

        mockLocalPathProvider.pathHandler = { _ in
            return nil
        }

        mockFileManager.removeItemHandler = { _ in
            throw ExposureDataError.internalError
        }

        mockFileManager.fileExistsHandler = { _, _ in
            return true
        }

        let exp = expectation(description: "Completion")
        _ = sut.execute()
            .subscribe(onError: { error in
                XCTAssertEqual(error as? ExposureDataError, ExposureDataError.internalError)
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(mockLocalPathProvider.pathCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_removeItem_withError_shouldMapExposureDataError() {

        mockStorage(
            storedKeySetHolders: [dummyKeySetHolder(withIdentifier: "SomeOldIdentifier")],
            initialKeySetsIgnored: true // Act as if the initial keyset was already ignored
        )

        mockFileManager.fileExistsHandler = { _, _ in
            return true
        }

        mockFileManager.removeItemHandler = { _ in
            throw ExposureDataError.internalError
        }

        mockFileManager.moveItemHandler = { _, _ in
            throw ExposureDataError.internalError
        }

        let exp = expectation(description: "Completion")
        _ = sut.execute()
            .subscribe(onError: { error in
                XCTAssertEqual(error as? ExposureDataError, ExposureDataError.internalError)
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(mockLocalPathProvider.pathCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_shouldNotDownloadKeySetsIfFirstBatchIsNotYetIgnored() {

        let exp = expectation(description: "expectation")

        mockStorage(
            storedKeySetHolders: [],
            initialKeySetsIgnored: false
        )

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockNetworkController.fetchExposureKeySetCallCount, 0)
    }

    func test_shouldDownloadKeySetsIfFirstBatchIsNotYetIgnoredButKeySetsAlreadyDownloaded() {

        let exp = expectation(description: "expectation")

        mockStorage(
            storedKeySetHolders: [dummyKeySetHolder(withIdentifier: "SomeOldIdentifier")],
            initialKeySetsIgnored: false
        )

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockNetworkController.fetchExposureKeySetCallCount, 1)
    }

    func test_shouldFakeProcessFirstKeySetBatch() {

        let exp = expectation(description: "expectation")
        let storedKeySetsExpectation = expectation(description: "storedKeySets")
        mockStorage(
            storedKeySetHolders: [],
            initialKeySetsIgnored: false
        )

        mockStorageController.storeHandler = { object, key, completion in
            guard (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString else {
                completion(nil)
                return
            }

            let keySetHolders = try! JSONDecoder().decode([ExposureKeySetHolder].self, from: object)

            // Check that all processdates of fake-processed keysets are more than 24 hours ago,
            // to avoid them interfering with GAEN API file limits on iOS 13.5
            let oneDay: TimeInterval = 60 * 60 * 24 - 1
            keySetHolders
                .compactMap { $0.processDate }
                .forEach { processDate in
                    XCTAssertTrue(currentDate().timeIntervalSince(processDate) >= oneDay)
                }

            storedKeySetsExpectation.fulfill()
            completion(nil)
        }

        sut.execute()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mockNetworkController.fetchExposureKeySetCallCount, 0)
    }

    private func dummyKeySetHolder(withIdentifier identifier: String = "identifier") -> ExposureKeySetHolder {
        ExposureKeySetHolder(identifier: identifier, signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: nil, creationDate: currentDate())
    }

    private func mockStorage(storedKeySetHolders: [ExposureKeySetHolder] = [],
                             initialKeySetsIgnored: Bool? = nil) {

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<[ExposureKeySetHolder]>)?.asString == ExposureDataStorageKey.exposureKeySetsHolders.asString {
                return try! JSONEncoder().encode(storedKeySetHolders)

            } else if (key as? CodableStorageKey<Bool>)?.asString == ExposureDataStorageKey.initialKeySetsIgnored.asString {
                return try! JSONEncoder().encode(initialKeySetsIgnored)
            }
            return nil
        }
    }
}

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
    private var mockKeySetDownloadProcessor: KeySetDownloadProcessingMock!

    private var exposureKeySetIdentifiers: [String]!

    override func setUp() {
        super.setUp()

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()
        mockKeySetDownloadProcessor = KeySetDownloadProcessingMock()

        exposureKeySetIdentifiers = ["identifier"]

        // Default handlers
        mockKeySetDownloadProcessor.processHandler = { _, _ in
            .empty()
        }

        mockKeySetDownloadProcessor.createIgnoredKeySetHolderHandler = { identifier in
            .just(.init(identifier: identifier, signatureFilename: "signatureFilename", binaryFilename: "binaryFilename", processDate: currentDate(), creationDate: currentDate()))
        }

        mockKeySetDownloadProcessor.storeDownloadedKeySetsHolderHandler = { _ in
            .empty()
        }

        mockKeySetDownloadProcessor.storeIgnoredKeySetsHoldersHandler = { _ in
            .empty()
        }

        mockNetworkController.fetchExposureKeySetHandler = { identifier, _ in
            return .just((identifier, URL(string: "http://someurl.com")!))
        }
        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }
        mockStorageController.storeHandler = { object, identifiedBy, completion in
            completion(nil)
        }

        sut = RequestExposureKeySetsDataOperation(
            networkController: mockNetworkController,
            storageController: mockStorageController,
            exposureKeySetIdentifiers: exposureKeySetIdentifiers,
            keySetDownloadProcessor: mockKeySetDownloadProcessor
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

        mockNetworkController.fetchExposureKeySetHandler = { identifier, _ in
            return .just((identifier, URL(string: "http://someurl.com")!))
        }

        sut.execute()
            .subscribe(onCompleted: {
                XCTAssertTrue(Thread.current.qualityOfService == .userInitiated)
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

        mockNetworkController.fetchExposureKeySetHandler = { _, _ in
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

        // Check that all processdates of fake-processed keysets are more than 24 hours ago,
        // to avoid them interfering with GAEN API file limits on iOS 13.5
        let oneDay: TimeInterval = 60 * 60 * 24 - 1
        mockKeySetDownloadProcessor.storeDownloadedKeySetsHolderArgValues
            .compactMap { $0.processDate }
            .forEach { processDate in
                XCTAssertTrue(currentDate().timeIntervalSince(processDate) >= oneDay)
            }

        XCTAssertEqual(mockKeySetDownloadProcessor.storeIgnoredKeySetsHoldersCallCount, 1)
        XCTAssertEqual(mockNetworkController.fetchExposureKeySetCallCount, 0)
    }

    // MARK: - Private helper functions

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

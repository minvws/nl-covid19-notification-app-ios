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

final class UpdateTreatmentPerspectiveDataOperationTests: TestCase {
    private var sut: UpdateTreatmentPerspectiveDataOperation!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!
    private let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()

        mockNetworkController.treatmentPerspectiveHandler = { identifier in .just(.fallbackMessage) }
        mockStorageController.storeHandler = { data, key, completion in completion(nil) }

        sut = UpdateTreatmentPerspectiveDataOperation(networkController: mockNetworkController,
                                                      storageController: mockStorageController)
    }

    func test_execute_shouldRetrieveManifestFromStorage() {

        let storageExpectation = expectation(description: "storage")

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ApplicationManifest>)?.asString == ExposureDataStorageKey.appManifest.asString {
                storageExpectation.fulfill()
                return try! JSONEncoder().encode(ApplicationManifest.testData())
            }

            return nil
        }

        _ = sut.execute()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_execute_shouldRequestTreatmentPerspectiveFromNetwork() {

        let storedManifest = ApplicationManifest.testData(creationDate: currentDate(), appConfigurationIdentifier: "SomeIdentifier")
        let streamExpectation = expectation(description: "stream")
        let networkCallExpectation = expectation(description: "networkCallExpectation")

        mockNetworkController.treatmentPerspectiveHandler = { identifier in
            networkCallExpectation.fulfill()
            return .just(.fallbackMessage)
        }

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ApplicationManifest>)?.asString == ExposureDataStorageKey.appManifest.asString {
                return try! JSONEncoder().encode(storedManifest)
            }
            return nil
        }

        _ = sut.execute()
            .subscribe(onCompleted: {
                streamExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertEqual(mockNetworkController.treatmentPerspectiveCallCount, 1)
    }

    func test_execute_shouldStoreRetrievedTreatmentPerspective() {

        let storedManifest = ApplicationManifest.testData(creationDate: currentDate(), appConfigurationIdentifier: "SomeIdentifier")
        let streamExpectation = expectation(description: "stream")
        let storageExpectation = expectation(description: "storageExpectation")

        mockNetworkController.treatmentPerspectiveHandler = { identifier in
            return .just(.fallbackMessage)
        }

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ApplicationManifest>)?.asString == ExposureDataStorageKey.appManifest.asString {
                return try! JSONEncoder().encode(storedManifest)
            }
            return nil
        }

        mockStorageController.storeHandler = { data, key, completion in
            if (key as? CodableStorageKey<TreatmentPerspective>)?.asString == ExposureDataStorageKey.treatmentPerspective.asString {
                storageExpectation.fulfill()
            }
            completion(nil)
        }

        _ = sut.execute()
            .subscribe(onCompleted: {
                streamExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)
    }
}

private extension ApplicationManifest {
    static func testData(creationDate: Date = currentDate(), appConfigurationIdentifier: String = "appConfigurationIdentifier") -> ApplicationManifest {
        ApplicationManifest(exposureKeySetsIdentifiers: [], riskCalculationParametersIdentifier: "riskCalculationParametersIdentifier", appConfigurationIdentifier: appConfigurationIdentifier, creationDate: creationDate, resourceBundle: "resourceBundle")
    }
}

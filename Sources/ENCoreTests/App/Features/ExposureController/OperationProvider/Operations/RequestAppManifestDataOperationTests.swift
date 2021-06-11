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

final class RequestAppManifestDataOperationTests: TestCase {
    private var sut: RequestAppManifestDataOperation!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!

    override func setUp() {
        super.setUp()

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()

        sut = RequestAppManifestDataOperation(networkController: mockNetworkController,
                                              storageController: mockStorageController)
    }

    func test_execute_shouldRetrieveApplicationConfigurationFromStorage() {

        let completionExpectation = expectation(description: "completion")
        let storageExpectation = expectation(description: "storage")

        mockStorageController.retrieveDataHandler = { key in
            
            XCTAssertTrue(Thread.current.qualityOfService == .userInitiated)
            
            if (key as? CodableStorageKey<ApplicationConfiguration>)?.asString == ExposureDataStorageKey.appConfiguration.asString {
                storageExpectation.fulfill()
                return try! JSONEncoder().encode(ApplicationConfiguration.testData())
            } else if (key as? CodableStorageKey<ApplicationManifest>)?.asString == ExposureDataStorageKey.appManifest.asString {
                return try! JSONEncoder().encode(ApplicationManifest.testData())
            }

            return nil
        }

        sut.execute()
            .subscribe(onSuccess: { (manifest) in
                XCTAssertTrue(Thread.current.qualityOfService == .userInitiated)
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_execute_shouldRetrieveManifestFromStorage() {

        let completionExpectation = expectation(description: "completion")
        let storageExpectation = expectation(description: "storage")

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ApplicationManifest>)?.asString == ExposureDataStorageKey.appManifest.asString {
                storageExpectation.fulfill()
                return try! JSONEncoder().encode(ApplicationManifest.testData())
            }

            return nil
        }

        sut.execute()
            .subscribe(onSuccess: { (manifest) in
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_execute_shouldReturnValidManifestFromStorage() {

        let storedConfiguration = ApplicationConfiguration.testData(manifestRefreshFrequency: 3600)
        let storedManifest = ApplicationManifest.testData(creationDate: currentDate().addingTimeInterval(-10), appConfigurationIdentifier: "SomeIdentifier")
        let streamExpectation = expectation(description: "stream")

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ApplicationConfiguration>)?.asString == ExposureDataStorageKey.appConfiguration.asString {
                return try! JSONEncoder().encode(storedConfiguration)
            } else if (key as? CodableStorageKey<ApplicationManifest>)?.asString == ExposureDataStorageKey.appManifest.asString {
                return try! JSONEncoder().encode(storedManifest)
            }
            return nil
        }

        _ = sut.execute()
            .subscribe(onSuccess: { manifest in
                XCTAssertEqual(manifest.appConfigurationIdentifier, "SomeIdentifier")
                streamExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertEqual(mockStorageController.storeCallCount, 0)
    }

    func test_execute_shouldReturnNetworkManifestIfStoredManifestIsInvalid() {

        let storedConfiguration = ApplicationConfiguration.testData(manifestRefreshFrequency: 60) // refesh manifest every 60 minutes
        let twoHours: TimeInterval = 2 * 60 * 60
        let storedManifest = ApplicationManifest.testData(creationDate: currentDate().addingTimeInterval(-twoHours), appConfigurationIdentifier: "SomeIdentifier")
        let apiManifest = ApplicationManifest.testData(creationDate: currentDate().addingTimeInterval(-10), appConfigurationIdentifier: "ApiManifestConfigurationIdentifier")
        let streamExpectation = expectation(description: "stream")
        let storeExpectation = expectation(description: "storeExpectation")

        mockNetworkController.applicationManifest = .just(apiManifest)

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ApplicationConfiguration>)?.asString == ExposureDataStorageKey.appConfiguration.asString {
                return try! JSONEncoder().encode(storedConfiguration)
            } else if (key as? CodableStorageKey<ApplicationManifest>)?.asString == ExposureDataStorageKey.appManifest.asString {
                return try! JSONEncoder().encode(storedManifest)
            }
            return nil
        }

        mockStorageController.storeHandler = { _, _, completion in
            storeExpectation.fulfill()
            completion(nil)
        }

        _ = sut.execute()
            .subscribe(onSuccess: { manifest in
                XCTAssertEqual(manifest.appConfigurationIdentifier, "ApiManifestConfigurationIdentifier")
                streamExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertEqual(mockStorageController.storeCallCount, 1)
    }

    func test_execute_shouldThrowErrorIfNetworkControllerReturnedError() {

        let storedConfiguration = ApplicationConfiguration.testData()
        let streamExpectation = expectation(description: "stream")

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ApplicationConfiguration>)?.asString == ExposureDataStorageKey.appConfiguration.asString {
                return try! JSONEncoder().encode(storedConfiguration)
            }
            return nil
        }

        mockNetworkController.applicationManifest = .error(NetworkError.serverNotReachable)

        _ = sut.execute()
            .subscribe(onFailure: { error in
                XCTAssertEqual(error as? ExposureDataError, ExposureDataError.networkUnreachable)
                streamExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func test_execute_shouldThrowErrorIfManifestCouldNotBeStoredDueToMisingIdentifier() {

        let storedConfiguration = ApplicationConfiguration.testData()
        let streamExpectation = expectation(description: "stream")
        let apiManifest = ApplicationManifest.testData(appConfigurationIdentifier: "") // Empty appConfigurationIdentifier will trigger a storage error

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ApplicationConfiguration>)?.asString == ExposureDataStorageKey.appConfiguration.asString {
                return try! JSONEncoder().encode(storedConfiguration)
            }
            return nil
        }

        mockNetworkController.applicationManifest = .just(apiManifest)

        _ = sut.execute()
            .subscribe(onFailure: { error in
                XCTAssertEqual(error as? ExposureDataError, ExposureDataError.serverError)
                streamExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertEqual(mockStorageController.storeCallCount, 0)
    }
}

private extension ApplicationConfiguration {
    static func testData(manifestRefreshFrequency: Int = 3600) -> ApplicationConfiguration {
        ApplicationConfiguration(version: 1, manifestRefreshFrequency: manifestRefreshFrequency, decoyProbability: 2, creationDate: currentDate(), identifier: "identifier", minimumVersion: "1.0.0", minimumVersionMessage: "minimumVersionMessage", appStoreURL: "appStoreURL", requestMinimumSize: 1, requestMaximumSize: 1, repeatedUploadDelay: 1, decativated: false, appointmentPhoneNumber: "appointmentPhoneNumber", featureFlags: [])
    }
}

private extension ApplicationManifest {
    static func testData(creationDate: Date = currentDate(), appConfigurationIdentifier: String = "appConfigurationIdentifier") -> ApplicationManifest {
        ApplicationManifest(exposureKeySetsIdentifiers: [], riskCalculationParametersIdentifier: "riskCalculationParametersIdentifier", appConfigurationIdentifier: appConfigurationIdentifier, creationDate: creationDate, resourceBundle: "resourceBundle")
    }
}

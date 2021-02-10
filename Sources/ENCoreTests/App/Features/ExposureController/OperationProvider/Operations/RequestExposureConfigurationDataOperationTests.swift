/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import RxSwift
import XCTest

final class RequestExposureConfigurationDataOperationTests: TestCase {
    private var operation: RequestExposureConfigurationDataOperation!
    private var exposureConfigurationIdentifier: String!
    private var mockNetworkController: NetworkControllingMock!
    private var mockStorageController: StorageControllingMock!

    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()

        mockNetworkController = NetworkControllingMock()
        mockStorageController = StorageControllingMock()
        exposureConfigurationIdentifier = "test"

        mockStorageController.requestExclusiveAccessHandler = { $0(self.mockStorageController) }

        operation = RequestExposureConfigurationDataOperation(networkController: mockNetworkController,
                                                              storageController: mockStorageController,
                                                              exposureConfigurationIdentifier: exposureConfigurationIdentifier)
    }

    func test_execute_withStoredConfigurationForIdentifier_shouldReturnStoredConfiguration() {

        let storedConfiguration = createConfiguration()

        mockStorageController.retrieveDataHandler = { key in
            if (key as? CodableStorageKey<ExposureRiskConfiguration>)?.asString == ExposureDataStorageKey.exposureConfiguration.asString {
                return try! JSONEncoder().encode(storedConfiguration)
            }
            return nil
        }

        let exp = expectation(description: "Completion")

        operation.execute()
            .subscribe(onSuccess: { configuration in
                XCTAssertEqual(configuration as? ExposureRiskConfiguration, storedConfiguration)
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(mockNetworkController.exposureRiskConfigurationParametersCallCount, 0)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_withoutStoredConfiguration_shouldRetrieveFromNetwork_andStoreConfiguration() {

        let networkConfiguration = createConfiguration(withIdentifier: "appconfig from network")

        let completionExpectation = expectation(description: "Completion")
        let storageExpectation = expectation(description: "Completion")
        var storedConfiguration: ExposureRiskConfiguration?

        mockStorageController.retrieveDataHandler = { _ in return nil }
        mockNetworkController.exposureRiskConfigurationParametersHandler = { identifier in
            return .just(networkConfiguration)
        }

        mockStorageController.storeHandler = { data, identifiedBy, completion in
            let jsonDecoder = JSONDecoder()
            storedConfiguration = try! jsonDecoder.decode(ExposureRiskConfiguration.self, from: data)

            storageExpectation.fulfill()
            completion(nil)
        }

        operation.execute()
            .subscribe(onSuccess: { configuration in
                XCTAssertEqual(configuration as? ExposureRiskConfiguration, networkConfiguration)
                completionExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(mockNetworkController.exposureRiskConfigurationParametersCallCount, 1)
        XCTAssertEqual(storedConfiguration, networkConfiguration)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_execute_retrieveFromNetwork_withError_shouldMapExposureDataError() {

        mockStorageController.retrieveDataHandler = { _ in return nil }
        mockNetworkController.exposureRiskConfigurationParametersHandler = { identifier in
            return .error(NetworkError.invalidRequest)
        }

        let exp = expectation(description: "Completion")

        operation.execute()
            .subscribe(onFailure: { error in
                guard case ExposureDataError.internalError = error else {
                    XCTFail("Call expected to return an error but succeeded instead")
                    return
                }

                exp.fulfill()
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(mockNetworkController.exposureRiskConfigurationParametersCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    // MARK: - Helper functions

    private func createConfiguration(withIdentifier identifier: String = "test") -> ExposureRiskConfiguration {
        ExposureRiskConfiguration(
            identifier: identifier,
            minimumRiskScore: 1,
            attenuationLevelValues: [2],
            daysSinceLastExposureLevelValues: [3],
            durationLevelValues: [4],
            transmissionRiskLevelValues: [5],
            attenuationDurationThresholds: [6],
            reportTypeWeights: [7],
            infectiousnessWeights: [8],
            attenuationBucketThresholdDb: [9],
            attenuationBucketWeights: [10],
            daysSinceExposureThreshold: 11,
            minimumWindowScore: 12,
            daysSinceOnsetToInfectiousness: [13]
        )
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

/// @mockable
protocol RequestExposureConfigurationDataOperationProtocol {
    func execute() -> Single<ExposureConfiguration>
}

final class RequestExposureConfigurationDataOperation: RequestExposureConfigurationDataOperationProtocol {
    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureConfigurationIdentifier: String) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureConfigurationIdentifier = exposureConfigurationIdentifier
    }

    // MARK: - ExposureDataOperation

    func execute() -> Single<ExposureConfiguration> {

        // Hardcoded ExposureRiskConfiguration until the API serves us this via a new endpoint
        return .just(ExposureRiskConfiguration(
            identifier: "identifier",
            minimumRiskScore: 900,
            reportTypeWeights: [0.0, 1.0, 1.0, 0.0, 0.0, 0.0],
            reportTypeWhenMissing: 1,
            infectiousnessWeights: [0.0, 1.0, 2.0],
            attenuationBucketThresholdDb: [56, 62, 70],
            attenuationBucketWeights: [1.0, 1.0, 0.3, 0.0],
            daysSinceExposureThreshold: 10,
            minimumWindowScore: 900, // 900 seconds is 15 minutes
            daysSinceOnsetToInfectiousness: [
                .init(daysSinceOnsetOfSymptoms: -14, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -13, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -12, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -11, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -10, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -9, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -8, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -7, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -6, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -5, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -4, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -3, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -2, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: -1, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 0, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 1, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 2, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 3, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 4, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 5, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 6, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 7, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 8, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 9, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 10, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 11, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 12, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 13, infectiousness: 1),
                .init(daysSinceOnsetOfSymptoms: 14, infectiousness: 1)
            ],
            infectiousnessWhenDaysSinceOnsetMissing: 1
        ))

//        if let exposureConfiguration = retrieveStoredConfiguration(), exposureConfiguration.identifier == exposureConfigurationIdentifier {
//            return .just(exposureConfiguration)
//        }
//
//        return networkController
//            .exposureRiskConfigurationParameters(identifier: exposureConfigurationIdentifier)
//            .subscribe(on: MainScheduler.instance)
//            .catch { throw $0.asExposureDataError }
//            .flatMap(store(exposureConfiguration:))
    }

    // MARK: - Private

    private func retrieveStoredConfiguration() -> ExposureRiskConfiguration? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureConfiguration)
    }

    private func store(exposureConfiguration: ExposureRiskConfiguration) -> Single<ExposureConfiguration> {
        return .create { observer in
            self.storageController.store(
                object: exposureConfiguration,
                identifiedBy: ExposureDataStorageKey.exposureConfiguration,
                completion: { error in
                    if error != nil {
                        observer(.failure(ExposureDataError.internalError))
                    } else {
                        observer(.success(exposureConfiguration))
                    }
                }
            )
            return Disposables.create()
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureConfigurationIdentifier: String
}

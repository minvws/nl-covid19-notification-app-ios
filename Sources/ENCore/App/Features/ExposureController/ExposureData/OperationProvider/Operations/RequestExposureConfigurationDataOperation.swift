/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

struct ExposureRiskConfiguration: Codable, ExposureConfiguration, Equatable {

    let identifier: String
    let minimumRiskScore: Double

    // v1
    let attenuationLevelValues: [UInt8]
    let daysSinceLastExposureLevelValues: [UInt8]
    let durationLevelValues: [UInt8]
    let transmissionRiskLevelValues: [UInt8]
    let attenuationDurationThresholds: [Int]

    // v2
    var scoreType: Int
    var reportTypeWeights: [Double]
    var infectiousnessWeights: [Double]
    var attenuationBucketThresholdDb: [UInt8]
    var attenuationBucketWeights: [Double]
    var daysSinceExposureThreshold: UInt
    var minimumWindowScore: Double
    var daysSinceOnsetToInfectiousness: [UInt8]
}

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
        if let exposureConfiguration = retrieveStoredConfiguration(), exposureConfiguration.identifier == exposureConfigurationIdentifier {
            return .just(exposureConfiguration)
        }

        return networkController
            .exposureRiskConfigurationParameters(identifier: exposureConfigurationIdentifier)
            .subscribe(on: MainScheduler.instance)
            .catch { throw $0.asExposureDataError }
            .flatMap(store(exposureConfiguration:))
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

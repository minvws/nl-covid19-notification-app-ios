/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct ExposureRiskConfiguration: Codable, ExposureConfiguration {
    let identifier: String

    let minimumRiskScope: UInt8
    let attenuationLevelValues: [Int]
    let daysSinceLastExposureLevelValues: [Int]
    let durationLevelValues: [Int]
    let transmissionRiskLevelValues: [Int]
    let attenuationDurationThresholds: [Int]
}

final class RequestExposureConfigurationDataOperation: ExposureDataOperation {
    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureConfigurationIdentifier: String) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureConfigurationIdentifier = exposureConfigurationIdentifier
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<ExposureConfiguration, ExposureDataError> {
        if let exposureConfiguration = retrieveStoredConfiguration(), exposureConfiguration.identifier == exposureConfigurationIdentifier {
            return Just(exposureConfiguration)
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        return networkController
            .exposureRiskConfigurationParameters(identifier: exposureConfigurationIdentifier)
            .mapError { $0.asExposureDataError }
            .flatMap(store(exposureConfiguration:))
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func retrieveStoredConfiguration() -> ExposureRiskConfiguration? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureConfiguration)
    }

    private func store(exposureConfiguration: ExposureRiskConfiguration) -> AnyPublisher<ExposureConfiguration, ExposureDataError> {
        return Future { promise in
            self.storageController.store(object: exposureConfiguration,
                                         identifiedBy: ExposureDataStorageKey.exposureConfiguration,
                                         completion: { _ in
                                             promise(.success(exposureConfiguration))
            })
        }
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureConfigurationIdentifier: String
}

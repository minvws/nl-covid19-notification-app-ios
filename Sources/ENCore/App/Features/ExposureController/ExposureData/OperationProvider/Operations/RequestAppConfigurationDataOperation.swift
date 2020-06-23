/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct ApplicationConfiguration: Codable {
    let version: Int
    let manifestRefreshFrequency: Int
    let decoyProbability: Int
    let creationDate: Date
    let identifier: String
}

final class RequestAppConfigurationDataOperation: ExposureDataOperation {
    typealias Result = ApplicationConfiguration

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         appConfigurationIdentifier: String) {
        self.networkController = networkController
        self.storageController = storageController
        self.appConfigurationIdentifier = appConfigurationIdentifier
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        if let appConfiguration = retrieveStoredConfiguration(), appConfiguration.identifier == appConfigurationIdentifier {
            return Just(appConfiguration)
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        return networkController
            .applicationConfiguration(identifier: appConfigurationIdentifier)
            .mapError { $0.asExposureDataError }
            .flatMap(store(appConfiguration:))
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func retrieveStoredConfiguration() -> ApplicationConfiguration? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appConfiguration,
                                                ofType: ApplicationConfiguration.self)
    }

    private func store(appConfiguration: ApplicationConfiguration) -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        return Future { promise in
            self.storageController.store(object: appConfiguration,
                                         identifiedBy: ExposureDataStorageKey.appConfiguration,
                                         completion: { _ in
                                             promise(.success(appConfiguration))
            })
        }
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let appConfigurationIdentifier: String
}

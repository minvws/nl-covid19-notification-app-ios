/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

struct ApplicationConfiguration: Codable {
    let version: Int
    let manifestRefreshFrequency: Int
    let decoyProbability: Float
    let creationDate: Date
    let identifier: String
    let minimumVersion: String
    let minimumVersionMessage: String
    let appStoreURL: String
    let requestMinimumSize: Int
    let requestMaximumSize: Int
    let repeatedUploadDelay: Int
    let decativated: Bool
    let testPhase: Bool
}

final class RequestAppConfigurationDataOperation: ExposureDataOperation, Logging {
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
            .share()
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func retrieveStoredConfiguration() -> ApplicationConfiguration? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appConfiguration)
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

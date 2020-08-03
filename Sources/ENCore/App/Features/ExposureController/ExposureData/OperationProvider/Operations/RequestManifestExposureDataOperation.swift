/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

struct ApplicationManifest: Codable {
    let exposureKeySetsIdentifiers: [String]
    let riskCalculationParametersIdentifier: String
    let appConfigurationIdentifier: String
    let creationDate: Date
    let iOSMinimumKillVersion: String?
}

final class RequestAppManifestDataOperation: ExposureDataOperation, Logging {
    typealias Result = ApplicationManifest

    private let defaultRefreshFrequency = 60 * 60 * 4 // 4 hours

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<ApplicationManifest, ExposureDataError> {
        let updateFrequency = retrieveManifestUpdateFrequency()

        if let manifest = retrieveStoredManifest(), manifest.isValid(forUpdateFrequency: updateFrequency) {
            return Just(manifest)
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        return networkController
            .applicationManifest
            .mapError { $0.asExposureDataError }
            .flatMap(store(manifest:))
            .share()
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func retrieveManifestUpdateFrequency() -> Int {
        guard let appConfiguration = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appConfiguration) else {
            return defaultRefreshFrequency
        }

        return appConfiguration.manifestRefreshFrequency
    }

    private func retrieveStoredManifest() -> ApplicationManifest? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appManifest)
    }

    private func store(manifest: ApplicationManifest) -> AnyPublisher<ApplicationManifest, ExposureDataError> {
        return Future { promise in
            self.storageController.store(object: manifest,
                                         identifiedBy: ExposureDataStorageKey.appManifest,
                                         completion: { _ in
                                             promise(.success(manifest))
                                         })
        }
        .share()
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

extension ApplicationManifest {
    func isValid(forUpdateFrequency updateFrequency: Int) -> Bool {
        return creationDate.addingTimeInterval(TimeInterval(updateFrequency)) >= Date()
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift

struct ApplicationManifest: Codable {
    let exposureKeySetsIdentifiers: [String]
    let riskCalculationParametersIdentifier: String
    let appConfigurationIdentifier: String
    let creationDate: Date
    let resourceBundle: String?
}

/// @mockable
protocol RequestAppManifestDataOperationProtocol {
    func execute() -> Single<ApplicationManifest>
}

final class RequestAppManifestDataOperation: RequestAppManifestDataOperationProtocol, Logging {

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    func execute() -> Single<ApplicationManifest> {
        let updateFrequency = retrieveManifestUpdateFrequency()

        if let manifest = retrieveStoredManifest(), manifest.isValid(forUpdateFrequency: updateFrequency) {
            logDebug("Using cached manifest")
            return .just(manifest)
        }

        logDebug("Getting fresh manifest from network")

        return networkController
            .applicationManifest
            .subscribe(on: MainScheduler.instance)
            .catch { throw $0.asExposureDataError }
            .flatMap(store(manifest:))
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

    private func store(manifest: ApplicationManifest) -> Single<ApplicationManifest> {
        let observable: Single<ApplicationManifest> = .create { observer in

            guard !manifest.appConfigurationIdentifier.isEmpty else {
                observer(.failure(ExposureDataError.serverError))
                return Disposables.create()
            }

            self.storageController.store(
                object: manifest,
                identifiedBy: ExposureDataStorageKey.appManifest,
                completion: { _ in
                    observer(.success(manifest))
                })

            return Disposables.create()
        }

        return observable
    }

    private let defaultRefreshFrequency = 60 * 4 // 4 hours
    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

extension ApplicationManifest {
    func isValid(forUpdateFrequency updateFrequency: Int) -> Bool {
        let expirationTimeInSeconds = TimeInterval(updateFrequency * 60)
        let expirationDate = creationDate.addingTimeInterval(expirationTimeInSeconds)
        return expirationDate >= currentDate()
    }
}

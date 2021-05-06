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
            let expirationDate = manifest.expirationDate(forUpdateFrequency: updateFrequency)
            logDebug("Using cached manifest (expires at \(expirationDate), in \(expirationDate.timeIntervalSince(Date()).minutes) minutes)")
            let manifestSingle = Single<ApplicationManifest>.create { (observer) in
                observer(.success(manifest))
                return Disposables.create()
            }
            return manifestSingle.observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        }

        logDebug("Getting fresh manifest from network")

        return networkController
            .applicationManifest
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
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
        return expirationDate(forUpdateFrequency: updateFrequency) >= currentDate()
    }
    
    func expirationDate(forUpdateFrequency updateFrequency: Int) -> Date {
        let expirationTimeInSeconds = TimeInterval(updateFrequency * 60)
        return creationDate.addingTimeInterval(expirationTimeInSeconds)
    }
}

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

final class RequestAppManifestDataOperation: Logging {

    private let defaultRefreshFrequency = 60 * 4 // 4 hours

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> Observable<ApplicationManifest> {
        let updateFrequency = retrieveManifestUpdateFrequency()

        if let manifest = retrieveStoredManifest(), manifest.isValid(forUpdateFrequency: updateFrequency) {
            logDebug("Using cached manifest")
            return .just(manifest)
        }

        logDebug("Getting fresh manifest from network")

        return networkController
            .applicationManifest
            .catch { error in
                throw (error as? NetworkError)?.asExposureDataError ?? ExposureDataError.internalError
            }
            .flatMap(store(manifest:))
            .share()
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

    private func store(manifest: ApplicationManifest) -> Observable<ApplicationManifest> {
        return .create { observer in

            guard !manifest.appConfigurationIdentifier.isEmpty else {
                observer.onError(ExposureDataError.serverError)
                return Disposables.create()
            }

            self.storageController.store(
                object: manifest,
                identifiedBy: ExposureDataStorageKey.appManifest,
                completion: { _ in
                    observer.onNext(manifest)
                    observer.onCompleted()
                })

            return Disposables.create()
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

extension ApplicationManifest {
    func isValid(forUpdateFrequency updateFrequency: Int) -> Bool {
        return creationDate.addingTimeInterval(TimeInterval(updateFrequency * 60)) >= Date()
    }
}

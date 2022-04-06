/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift

/// @mockable
protocol RequestDashboardDataOperationProtocol {
    func execute() -> Single<DashboardData>
}

final class RequestDashboardDataOperation: RequestDashboardDataOperationProtocol, Logging {
    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    func execute() -> Single<DashboardData> {

        let dashboardSingle = Single<DashboardData>.create { observer in

//            let updateFrequency = self.retrieveManifestUpdateFrequency()
//
//            if let manifest = self.retrieveStoredManifest(), manifest.isValid(forUpdateFrequency: updateFrequency) {
//                let expirationDate = manifest.expirationDate(forUpdateFrequency: updateFrequency)
//                self.logDebug("Using cached manifest (expires at \(expirationDate), in \(expirationDate.timeIntervalSince(Date()).minutes) minutes)")
//                observer(.success(manifest))
//                return Disposables.create()
//            }

            self.logDebug("Getting fresh manifest from network")

            return self.networkController
                .dashboardData
                .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .catch { throw $0.asExposureDataError }
//                .flatMap(self.store(manifest:))
                .subscribe(observer)
        }

        return dashboardSingle.subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }

    // MARK: - Private

//    private func retrieveManifestUpdateFrequency() -> Int {
//        guard let appConfiguration = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appConfiguration) else {
//            return defaultRefreshFrequency
//        }
//
//        return appConfiguration.manifestRefreshFrequency
//    }
//
//    private func retrieveStoredManifest() -> ApplicationManifest? {
//        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appManifest)
//    }
//
//    private func store(manifest: ApplicationManifest) -> Single<ApplicationManifest> {
//        let observable: Single<ApplicationManifest> = .create { observer in
//
//            guard !manifest.appConfigurationIdentifier.isEmpty else {
//                observer(.failure(ExposureDataError.serverError))
//                return Disposables.create()
//            }
//
//            self.storageController.store(
//                object: manifest,
//                identifiedBy: ExposureDataStorageKey.appManifest,
//                completion: { _ in
//                    observer(.success(manifest))
//                })
//
//            return Disposables.create()
//        }
//
//        return observable
//    }

    private let defaultRefreshFrequency = 60 * 4 // 4 hours
    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

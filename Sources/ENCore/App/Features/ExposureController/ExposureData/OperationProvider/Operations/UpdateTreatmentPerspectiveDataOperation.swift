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
protocol UpdateTreatmentPerspectiveDataOperationProtocol {
    func execute() -> Completable
}

final class UpdateTreatmentPerspectiveDataOperation: UpdateTreatmentPerspectiveDataOperationProtocol, Logging {

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> Completable {

        let output = Completable.create { (observer) -> Disposable in
            
            guard let manifest = self.retrieveStoredManifest(), let identifier = manifest.resourceBundle else {
                // can't update, just return a success message. We can get the stored treatment perspective from disk later on
                observer(.completed)
                return Disposables.create()
            }
            
            return self.networkController
                .treatmentPerspective(identifier: identifier)
                .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .catch { throw $0.asExposureDataError }
                .flatMapCompletable(self.store(treatmentPerspective:))
                .subscribe(observer)
        }
        
        return output.subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }

    // MARK: - Private

    private func retrieveStoredManifest() -> ApplicationManifest? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appManifest)
    }

    private func store(treatmentPerspective: TreatmentPerspective) -> Completable {
        return .create { (observer) -> Disposable in

            self.storageController.store(
                object: treatmentPerspective,
                identifiedBy: ExposureDataStorageKey.treatmentPerspective,
                completion: { error in
                    if error != nil {
                        observer(.error(ExposureDataError.internalError))
                    } else {
                        observer(.completed)
                    }
                })

            return Disposables.create()
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

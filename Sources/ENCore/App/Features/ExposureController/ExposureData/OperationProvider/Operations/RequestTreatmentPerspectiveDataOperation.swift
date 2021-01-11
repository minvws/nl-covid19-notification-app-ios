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
protocol RequestTreatmentPerspectiveDataOperationProtocol {
    func execute() -> Observable<TreatmentPerspective>
}

final class RequestTreatmentPerspectiveDataOperation: RequestTreatmentPerspectiveDataOperationProtocol, Logging {

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> Observable<TreatmentPerspective> {

        if let manifest = retrieveStoredManifest(),
            let identifier = manifest.resourceBundle {

            return networkController
                .treatmentPerspective(identifier: identifier)
                .subscribe(on: MainScheduler.instance)
                .catch { throw $0.asExposureDataError }
                .flatMap(store(treatmentPerspective:))
                .share()
        }

        if let storedTreatmentPerspective = retrieveStoredTreatmentPerspective() {
            return .just(storedTreatmentPerspective)
        }

        return .just(TreatmentPerspective.fallbackMessage)
    }

    // MARK: - Private

    private func retrieveStoredTreatmentPerspective() -> TreatmentPerspective? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspective)
    }

    private func retrieveStoredManifest() -> ApplicationManifest? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appManifest)
    }

    private func store(treatmentPerspective: TreatmentPerspective) -> Observable<TreatmentPerspective> {
        return .create { (observer) -> Disposable in

            self.storageController.store(
                object: treatmentPerspective,
                identifiedBy: ExposureDataStorageKey.treatmentPerspective,
                completion: { error in
                    if error != nil {
                        observer.onError(ExposureDataError.internalError)
                    } else {
                        observer.onNext(treatmentPerspective)
                        observer.onCompleted()
                    }
                })

            return Disposables.create()
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

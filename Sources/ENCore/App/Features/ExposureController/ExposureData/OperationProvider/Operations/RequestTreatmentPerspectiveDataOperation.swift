/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

final class RequestTreatmentPerspectiveDataOperation: ExposureDataOperation, Logging {
    typealias Result = TreatmentPerspective

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<TreatmentPerspective, ExposureDataError> {

        if let manifest = retrieveStoredManifest(),
            let identifier = manifest.resourceBundleId {

            return networkController
                .treatmentPerspective(identifier: identifier)
                .mapError { $0.asExposureDataError }
                .flatMap(store(treatmentPerspective:))
                .share()
                .eraseToAnyPublisher()
        }

        if let storedTreatmentPerspective = retrieveStoredTreatmentPerspective() {
            return Just(storedTreatmentPerspective)
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        return Just(TreatmentPerspective.fallbackMessage)
            .setFailureType(to: ExposureDataError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func retrieveStoredTreatmentPerspective() -> TreatmentPerspective? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspective)
    }

    private func retrieveStoredManifest() -> ApplicationManifest? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appManifest)
    }

    private func silentStore(treatmentPerspective: TreatmentPerspective) {
        self.storageController.store(object: treatmentPerspective,
                                     identifiedBy: ExposureDataStorageKey.treatmentPerspective,
                                     completion: { error in
                                         if let error = error {
                                             self.logError(error.localizedDescription)
                                         }
            })
    }

    private func store(treatmentPerspective: TreatmentPerspective) -> AnyPublisher<TreatmentPerspective, ExposureDataError> {
        return Future { promise in
            self.storageController.store(object: treatmentPerspective,
                                         identifiedBy: ExposureDataStorageKey.treatmentPerspective,
                                         completion: { _ in
                                             promise(.success(treatmentPerspective))
                })
        }
        .share()
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

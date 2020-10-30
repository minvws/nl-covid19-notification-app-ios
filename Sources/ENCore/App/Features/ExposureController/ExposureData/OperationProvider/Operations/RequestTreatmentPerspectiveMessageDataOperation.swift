/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

final class RequestTreatmentPerspectiveMessageDataOperation: ExposureDataOperation, Logging {
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
                .treatmentPerspectiveMessage(identifier: identifier)
                .mapError { $0.asExposureDataError }
                .flatMap(store(treatmentPerspectiveMessage:))
                .share()
                .eraseToAnyPublisher()
        }

        if let storedTreatmentPerspectiveMessage = retrieveStoredTreatmentPerspectiveMessage() {
            return Just(storedTreatmentPerspectiveMessage)
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        return Just(TreatmentPerspective.fallbackMessage)
            .setFailureType(to: ExposureDataError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func retrieveStoredTreatmentPerspectiveMessage() -> TreatmentPerspective? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage)
    }

    private func retrieveStoredManifest() -> ApplicationManifest? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appManifest)
    }

    private func silentStore(treatmentPerspectiveMessage: TreatmentPerspective) {
        self.storageController.store(object: treatmentPerspectiveMessage,
                                     identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage,
                                     completion: { error in
                                         if let error = error {
                                             self.logError(error.localizedDescription)
                                         }
            })
    }

    private func store(treatmentPerspectiveMessage: TreatmentPerspective) -> AnyPublisher<TreatmentPerspective, ExposureDataError> {
        return Future { promise in
            self.storageController.store(object: treatmentPerspectiveMessage,
                                         identifiedBy: ExposureDataStorageKey.treatmentPerspectiveMessage,
                                         completion: { _ in
                                             promise(.success(treatmentPerspectiveMessage))
                })
        }
        .share()
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

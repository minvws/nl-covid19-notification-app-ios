/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct ExposureKeySetHolder: Codable {
    let identifier: String
    let fileUrl: URL
    let processed: Bool
    let creationDate: Date
}

final class RequestExposureKeySetsDataOperation: ExposureDataOperation {
    typealias Result = [ExposureKeySetHolder]

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureKeySetIdentifiers: [String]) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureKeySetIdentifiers = exposureKeySetIdentifiers
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<[ExposureKeySetHolder], ExposureDataError> {
        let storedKeySetsHolders = getStoredKeySetsHolders()
        let identifiers = removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from: exposureKeySetIdentifiers,
                                                                              storedKeySetsHolders: storedKeySetsHolders)

        // download remaining keysets
        let exposureKeySetStreams: [AnyPublisher<ExposureKeySetHolder, NetworkError>] = identifiers.map { identifier in
            self.networkController
                .fetchExposureKeySet(identifier: identifier)
                .eraseToAnyPublisher()
        }

        // schedule all downloads at once - the networking layer should limit the number of parallel
        // requests if necessary
        return Publishers.Sequence<[AnyPublisher<ExposureKeySetHolder, NetworkError>], NetworkError>(sequence: exposureKeySetStreams)
            .flatMap { $0 }
            .mapError { error in error.asExposureDataError }
            .collect()
            .flatMap(self.storeDownloadedKeySetsHolders)
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func getStoredKeySetsHolders() -> [ExposureKeySetHolder] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []
    }

    private func removeAlreadyDownloadedOrProcessedKeySetIdentifiers(from identifiers: [String],
                                                                     storedKeySetsHolders: [ExposureKeySetHolder]) -> [String] {
        let isNotDownloadedOrProcessed: (String) -> Bool = { identifier in !storedKeySetsHolders.contains { $0.identifier == identifier } }
        return identifiers.filter(isNotDownloadedOrProcessed)
    }

    // stores the downloaded keysets holders and returns the final list of keysets holders on disk
    private func storeDownloadedKeySetsHolders(_ downloadedKeySetsHolders: [ExposureKeySetHolder]) -> AnyPublisher<[ExposureKeySetHolder], ExposureDataError> {
        return Future { promise in
            self.storageController.requestExclusiveAccess { storageController in
                var keySetsHolders = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? []

                downloadedKeySetsHolders.forEach { keySetsHolder in
                    let matchesKeySetsHolder: (ExposureKeySetHolder) -> Bool = { $0.identifier == keySetsHolder.identifier }

                    if !keySetsHolders.contains(where: matchesKeySetsHolder) {
                        keySetsHolders.append(keySetsHolder)
                    }
                }

                storageController.store(object: keySetsHolders,
                                        identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) { _ in
                    // ignore any storage error - in that case the keyset will be downloaded and processed again
                    promise(.success(keySetsHolders))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureKeySetIdentifiers: [String]
}

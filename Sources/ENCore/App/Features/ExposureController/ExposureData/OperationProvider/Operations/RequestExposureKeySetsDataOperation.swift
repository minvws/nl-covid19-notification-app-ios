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
        let exposureKeySetStreams: [AnyPublisher<ExposureKeySetHolder, NetworkError>] = exposureKeySetIdentifiers.map { identifier in
            self.networkController.fetchExposureKeySet(identifier: identifier).eraseToAnyPublisher()
        }

        let s = exposureKeySetStreams.serialize()!
            .mapError { $0.asExposureDataError }
            .collect()
            .eraseToAnyPublisher()

//        let s = Publishers.Sequence<[AnyPublisher<ExposureKeySetHolder, NetworkError>], NetworkError>(sequence: exposureKeySetStreams)
//            .flatMap(maxPublishers: .max(1)) { $0 }
//            .mapError { error in error.asExposureDataError }
//            .collect()
//            .eraseToAnyPublisher()

        return s
//        return s.map { [$0] }.eraseToAnyPublisher()
    }

    // MARK: - Private

    private func getStoredKeySetsHolders() -> [ExposureKeySetHolder] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders,
                                                ofType: [ExposureKeySetHolder].self) ?? []
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureKeySetIdentifiers: [String]
}

extension Collection where Element: Publisher {
    func serialize() -> AnyPublisher<Element.Output, Element.Failure>? {
        guard let start = self.first else { return nil }
        return self.dropFirst().reduce(start.eraseToAnyPublisher()) {
            $0.append($1).eraseToAnyPublisher()
        }
    }
}

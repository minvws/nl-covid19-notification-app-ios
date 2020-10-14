/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import CryptoKit
import Foundation

/// @mockable
protocol ApplicationSignatureControlling {
    func retrieveStoredConfiguration() -> ApplicationConfiguration?
    func store(appConfiguration: ApplicationConfiguration) -> AnyPublisher<ApplicationConfiguration, ExposureDataError>
    func storeSignature(for appConfiguration: ApplicationConfiguration) -> AnyPublisher<ApplicationConfiguration, ExposureDataError>
    func retrieveStoredSignature() -> Data?
    func signature(for appConfiguration: ApplicationConfiguration) -> Data?
}

final class ApplicationSignatureController: ApplicationSignatureControlling {

    init(storageController: StorageControlling,
         cryptoUtility: CryptoUtility) {
        self.storageController = storageController
        self.cryptoUtility = cryptoUtility
    }

    // MARK: - ApplicationSignatureController

    func retrieveStoredConfiguration() -> ApplicationConfiguration? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appConfiguration)
    }

    func store(appConfiguration: ApplicationConfiguration) -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        return Future { promise in
            guard appConfiguration.version > 0, appConfiguration.manifestRefreshFrequency > 0 else {
                return promise(.failure(.serverError))
            }
            self.storageController.store(object: appConfiguration,
                                         identifiedBy: ExposureDataStorageKey.appConfiguration,
                                         completion: { _ in
                                             promise(.success(appConfiguration))
                })
        }
        .eraseToAnyPublisher()
    }

    func retrieveStoredSignature() -> Data? {
        return storageController.retrieveData(identifiedBy: ExposureDataStorageKey.appConfigurationSignature)
    }

    func storeSignature(for appConfiguration: ApplicationConfiguration) -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        return Future { promise in
            guard let sha = self.signature(for: appConfiguration) else {
                promise(.failure(ExposureDataError.internalError))
                return
            }

            self.storageController.store(data: sha, identifiedBy: ExposureDataStorageKey.appConfigurationSignature) { _ in
                promise(.success(appConfiguration))
            }
        }
        .eraseToAnyPublisher()
    }

    func signature(for appConfiguration: ApplicationConfiguration) -> Data? {
        guard let encoded = try? JSONEncoder().encode(appConfiguration) else { return nil }
        return cryptoUtility.sha256(data: encoded)?.data(using: .utf8)
    }

    // MARK: - Private

    private let storageController: StorageControlling
    private let cryptoUtility: CryptoUtility
}

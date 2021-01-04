/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

/// @mockable
protocol ApplicationSignatureControlling {
    func retrieveStoredConfiguration() -> ApplicationConfiguration?
    func storeAppConfiguration(_ appConfiguration: ApplicationConfiguration) -> Observable<ApplicationConfiguration>
    func storeSignature(for appConfiguration: ApplicationConfiguration) -> Observable<ApplicationConfiguration>
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

    func storeAppConfiguration(_ appConfiguration: ApplicationConfiguration) -> Observable<ApplicationConfiguration> {
        return .create { (observer) -> Disposable in
            guard appConfiguration.version > 0, appConfiguration.manifestRefreshFrequency > 0 else {
                observer.onError(ExposureDataError.serverError)
                return Disposables.create()
            }

            self.storageController.store(
                object: appConfiguration,
                identifiedBy: ExposureDataStorageKey.appConfiguration,
                completion: { _ in
                    observer.onNext(appConfiguration)
                    observer.onCompleted()
                })

            return Disposables.create()
        }
    }

    func retrieveStoredSignature() -> Data? {
        return storageController.retrieveData(identifiedBy: ExposureDataStorageKey.appConfigurationSignature)
    }

    func storeSignature(for appConfiguration: ApplicationConfiguration) -> Observable<ApplicationConfiguration> {
        return .create { (observer) -> Disposable in

            guard let sha = self.signature(for: appConfiguration) else {
                observer.onError(ExposureDataError.internalError)
                return Disposables.create()
            }

            self.storageController.store(data: sha, identifiedBy: ExposureDataStorageKey.appConfigurationSignature) { _ in
                observer.onNext(appConfiguration)
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    func signature(for appConfiguration: ApplicationConfiguration) -> Data? {
        guard let encoded = try? JSONEncoder().encode(appConfiguration) else { return nil }
        return cryptoUtility.sha256(data: encoded)?.data(using: .utf8)
    }

    // MARK: - Private

    private let storageController: StorageControlling
    private let cryptoUtility: CryptoUtility
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

/// @mockable
protocol RequestExposureConfigurationDataOperationProtocol {
    func execute() -> Single<ExposureConfiguration>
}

final class RequestExposureConfigurationDataOperation: RequestExposureConfigurationDataOperationProtocol {
    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         exposureConfigurationIdentifier: String) {
        self.networkController = networkController
        self.storageController = storageController
        self.exposureConfigurationIdentifier = exposureConfigurationIdentifier
    }

    // MARK: - ExposureDataOperation

    func execute() -> Single<ExposureConfiguration> {

        let resultSingle = Single<ExposureConfiguration>.create { (observer) -> Disposable in
            
            if let exposureConfiguration = self.retrieveStoredConfiguration(), exposureConfiguration.identifier == self.exposureConfigurationIdentifier {
                observer(.success(exposureConfiguration))
                return Disposables.create()
            }
            
            return self.networkController
                .exposureRiskConfigurationParameters(identifier: self.exposureConfigurationIdentifier)                
                .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .catch { throw $0.asExposureDataError }
                .flatMap(self.store(exposureConfiguration:))
                .subscribe(observer)
        }
        
        return resultSingle.subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }

    // MARK: - Private

    private func retrieveStoredConfiguration() -> ExposureRiskConfiguration? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureConfiguration)
    }

    private func store(exposureConfiguration: ExposureRiskConfiguration) -> Single<ExposureConfiguration> {
        return .create { observer in
            self.storageController.store(
                object: exposureConfiguration,
                identifiedBy: ExposureDataStorageKey.exposureConfiguration,
                completion: { error in
                    if error != nil {
                        observer(.failure(ExposureDataError.internalError))
                    } else {
                        observer(.success(exposureConfiguration))
                    }
                }
            )
            return Disposables.create()
        }
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let exposureConfigurationIdentifier: String
}

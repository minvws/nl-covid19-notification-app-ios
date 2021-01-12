/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

struct ExposureRiskConfiguration: Codable, ExposureConfiguration, Equatable {
    let identifier: String

    let minimumRiskScope: UInt8
    let attenuationLevelValues: [UInt8]
    let daysSinceLastExposureLevelValues: [UInt8]
    let durationLevelValues: [UInt8]
    let transmissionRiskLevelValues: [UInt8]
    let attenuationDurationThresholds: [Int]
}

protocol RequestExposureConfigurationDataOperationProtocol {
    func execute() -> Observable<ExposureConfiguration>
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

    func execute() -> Observable<ExposureConfiguration> {
        if let exposureConfiguration = retrieveStoredConfiguration(), exposureConfiguration.identifier == exposureConfigurationIdentifier {
            return .just(exposureConfiguration)
        }

        return networkController
            .exposureRiskConfigurationParameters(identifier: exposureConfigurationIdentifier)
            .subscribe(on: MainScheduler.instance)
            .catch { throw $0.asExposureDataError }
            .flatMap(store(exposureConfiguration:))
            .share()
    }

    // MARK: - Private

    private func retrieveStoredConfiguration() -> ExposureRiskConfiguration? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureConfiguration)
    }

    private func store(exposureConfiguration: ExposureRiskConfiguration) -> Observable<ExposureConfiguration> {
        return .create { observer in
            self.storageController.store(
                object: exposureConfiguration,
                identifiedBy: ExposureDataStorageKey.exposureConfiguration,
                completion: { error in
                    if error != nil {
                        observer.onError(ExposureDataError.internalError)
                    } else {
                        observer.onNext(exposureConfiguration)
                        observer.onCompleted()
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

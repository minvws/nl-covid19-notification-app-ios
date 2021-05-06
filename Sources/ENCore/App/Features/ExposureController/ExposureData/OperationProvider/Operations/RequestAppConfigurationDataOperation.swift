/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift

struct ApplicationConfiguration: Codable, Equatable {
    let version: Int
    let manifestRefreshFrequency: Int
    let decoyProbability: Float
    let creationDate: Date
    let identifier: String
    let minimumVersion: String
    let minimumVersionMessage: String
    let appStoreURL: String
    let requestMinimumSize: Int
    let requestMaximumSize: Int
    let repeatedUploadDelay: Int
    let decativated: Bool
    let appointmentPhoneNumber: String
}

/// @mockable
protocol RequestAppConfigurationDataOperationProtocol {
    func execute() -> Single<ApplicationConfiguration>
}

final class RequestAppConfigurationDataOperation: RequestAppConfigurationDataOperationProtocol, Logging {

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         applicationSignatureController: ApplicationSignatureControlling,
         appConfigurationIdentifier: String) {
        self.networkController = networkController
        self.storageController = storageController
        self.applicationSignatureController = applicationSignatureController
        self.appConfigurationIdentifier = appConfigurationIdentifier
    }

    // MARK: - ExposureDataOperation

    func execute() -> Single<ApplicationConfiguration> {
        self.logDebug("Started executing RequestAppConfigurationDataOperation with identifier: \(appConfigurationIdentifier)")

        if let appConfiguration = applicationSignatureController.retrieveStoredConfiguration(),
            let storedSignature = applicationSignatureController.retrieveStoredSignature(),
            appConfiguration.identifier == appConfigurationIdentifier,
            storedSignature == applicationSignatureController.signature(for: appConfiguration) {

            self.logDebug("RequestAppConfigurationDataOperation: Using cached version")

            return .just(appConfiguration)
        }

        self.logDebug("RequestAppConfigurationDataOperation: Using network version")

        return networkController
            .applicationConfiguration(identifier: appConfigurationIdentifier)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .catch { throw $0.asExposureDataError }
            .flatMap(storeAppConfiguration)
            .flatMap(storeSignature(for:))
    }

    private func storeAppConfiguration(_ appConfiguration: ApplicationConfiguration) -> Single<ApplicationConfiguration> {
        return applicationSignatureController.storeAppConfiguration(appConfiguration)
    }

    private func storeSignature(for appConfiguration: ApplicationConfiguration) -> Single<ApplicationConfiguration> {
        return applicationSignatureController.storeSignature(for: appConfiguration)
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let applicationSignatureController: ApplicationSignatureControlling
    private let appConfigurationIdentifier: String
}

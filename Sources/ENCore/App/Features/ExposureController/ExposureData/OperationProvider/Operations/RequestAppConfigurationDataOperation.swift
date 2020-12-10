/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

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

final class RequestAppConfigurationDataOperation: ExposureDataOperation, Logging {

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

    func execute() -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        self.logDebug("Started executing RequestAppConfigurationDataOperation with identifier: \(appConfigurationIdentifier)")

        if let appConfiguration = applicationSignatureController.retrieveStoredConfiguration(),
            let storedSignature = applicationSignatureController.retrieveStoredSignature(),
            appConfiguration.identifier == appConfigurationIdentifier,
            storedSignature == applicationSignatureController.signature(for: appConfiguration) {

            self.logDebug("RequestAppConfigurationDataOperation: Using cached version")

            return Just(appConfiguration)
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        self.logDebug("RequestAppConfigurationDataOperation: Using network version")

        return networkController
            .applicationConfiguration(identifier: appConfigurationIdentifier)
            .mapError { $0.asExposureDataError }
            .flatMap(storeAppConfiguration)
            .flatMap(storeSignature(for:))
            .share()
            .eraseToAnyPublisher()
    }

    private func storeAppConfiguration(_ appConfiguration: ApplicationConfiguration) -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        return self.applicationSignatureController.storeAppConfiguration(appConfiguration)
            .share()
            .eraseToAnyPublisher()
    }

    private func storeSignature(for appConfiguration: ApplicationConfiguration) -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        return self.applicationSignatureController.storeSignature(for: appConfiguration)
            .share()
            .eraseToAnyPublisher()
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let applicationSignatureController: ApplicationSignatureControlling
    private let appConfigurationIdentifier: String
}

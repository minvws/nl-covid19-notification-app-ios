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
    let featureFlags: [FeatureFlag]
    let scheduledNotification: ScheduledNotification?
    let shareKeyURL: String?

    struct FeatureFlag: Codable, Equatable {
        let id: String
        let featureEnabled: Bool
    }

    struct ScheduledNotification: Codable, Equatable {
        let scheduledDateTime: String
        let title: String
        let body: String
        let targetScreen: String

        func scheduledDateTimeComponents() -> DateComponents? {
            guard let scheduledDate = Date().toDate(scheduledDateTime) else {
                return nil
            }

            let scheduledDateComponents = Calendar.current.dateComponents([
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .timeZone
            ],
            from: scheduledDate)

            var date = DateComponents()
            date.year = scheduledDateComponents.year
            date.month = scheduledDateComponents.month
            date.day = scheduledDateComponents.day
            date.hour = scheduledDateComponents.hour
            date.minute = scheduledDateComponents.minute
            date.timeZone = scheduledDateComponents.timeZone

            return date
        }

        func getTargetScreen() -> TargetScreen {
            if targetScreen.lowercased() == "share" {
                return .share
            }
            return .main
        }

        enum TargetScreen {
            case main, share
        }
    }
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
        logDebug("Started executing RequestAppConfigurationDataOperation with identifier: \(appConfigurationIdentifier)")

        let configurationSingle = Single<ApplicationConfiguration>.create { observer in

            if let appConfiguration = self.applicationSignatureController.retrieveStoredConfiguration(),
                let storedSignature = self.applicationSignatureController.retrieveStoredSignature(),
                appConfiguration.identifier == self.appConfigurationIdentifier,
                storedSignature == self.applicationSignatureController.signature(for: appConfiguration) {
                self.logDebug("RequestAppConfigurationDataOperation: Using cached version")

                observer(.success(appConfiguration))
                return Disposables.create()
            }

            self.logDebug("RequestAppConfigurationDataOperation: Using network version")

            return self.networkController
                .applicationConfiguration(identifier: self.appConfigurationIdentifier)
                .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .catch { throw $0.asExposureDataError }
                .flatMap(self.storeAppConfiguration)
                .flatMap(self.storeSignature)
                .subscribe(observer)
        }

        return configurationSingle.subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }

    private func storeAppConfiguration(_ appConfiguration: ApplicationConfiguration) -> Single<ApplicationConfiguration> {
        return applicationSignatureController.storeAppConfiguration(appConfiguration)
    }

    private func storeSignature(_ appConfiguration: ApplicationConfiguration) -> Single<ApplicationConfiguration> {
        return applicationSignatureController.storeSignature(for: appConfiguration)
    }

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let applicationSignatureController: ApplicationSignatureControlling
    private let appConfigurationIdentifier: String
}

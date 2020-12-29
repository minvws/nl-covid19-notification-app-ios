/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import NotificationCenter

protocol ExposureDataOperation {
    associatedtype Result

    func execute() -> AnyPublisher<Result, ExposureDataError>
}

/// @mockable
protocol ExposureDataOperationProvider {
    func processExposureKeySetsOperation(exposureManager: ExposureManaging,
                                         configuration: ExposureConfiguration) -> ProcessExposureKeySetsDataOperation?

    func processPendingLabConfirmationUploadRequestsOperation(padding: Padding) -> ProcessPendingLabConfirmationUploadRequestsDataOperation
    func expiredLabConfirmationNotificationOperation() -> ExpiredLabConfirmationNotificationDataOperation
    func requestAppConfigurationOperation(identifier: String) -> RequestAppConfigurationDataOperation
    func requestExposureConfigurationOperation(identifier: String) -> RequestExposureConfigurationDataOperationProtocol
    func requestExposureKeySetsOperation(identifiers: [String]) -> RequestExposureKeySetsDataOperation

    var requestManifestOperation: RequestAppManifestDataOperationProtocol { get }
    var requestTreatmentPerspectiveDataOperation: RequestTreatmentPerspectiveDataOperationProtocol { get }
    func requestLabConfirmationKeyOperation(padding: Padding) -> RequestLabConfirmationKeyDataOperation

    func uploadDiagnosisKeysOperation(diagnosisKeys: [DiagnosisKey],
                                      labConfirmationKey: LabConfirmationKey,
                                      padding: Padding) -> UploadDiagnosisKeysDataOperation
}

protocol ExposureDataOperationProviderBuildable {
    func build() -> ExposureDataOperationProvider
}

protocol ExposureDataOperationProviderDependency {
    var networkController: NetworkControlling { get }
    var storageController: StorageControlling { get }
    var applicationSignatureController: ApplicationSignatureControlling { get }
}

private final class ExposureDataOperationProviderDependencyProvider: DependencyProvider<ExposureDataOperationProviderDependency> {
    var localPathProvider: LocalPathProviding {
        return LocalPathProvider()
    }

    var userNotificationCenter: UserNotificationCenter {
        return UNUserNotificationCenter.current()
    }

    var application: ApplicationControlling {
        return ApplicationController()
    }

    var fileManager: FileManaging {
        return FileManager.default
    }

    var environmentController: EnvironmentControlling {
        return EnvironmentController()
    }
}

final class ExposureDataOperationProviderBuilder: Builder<ExposureDataOperationProviderDependency>, ExposureDataOperationProviderBuildable {
    func build() -> ExposureDataOperationProvider {
        let dependencyProvider = ExposureDataOperationProviderDependencyProvider(dependency: dependency)

        return ExposureDataOperationProviderImpl(networkController: dependencyProvider.dependency.networkController,
                                                 storageController: dependencyProvider.dependency.storageController,
                                                 applicationSignatureController: dependencyProvider.dependency.applicationSignatureController,
                                                 localPathProvider: dependencyProvider.localPathProvider,
                                                 userNotificationCenter: dependencyProvider.userNotificationCenter,
                                                 application: dependencyProvider.application,
                                                 fileManager: dependencyProvider.fileManager,
                                                 environmentController: dependencyProvider.environmentController)
    }
}

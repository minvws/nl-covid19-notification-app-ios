/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

final class ExposureDataOperationProviderImpl: ExposureDataOperationProvider, Logging {

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         applicationSignatureController: ApplicationSignatureControlling,
         localPathProvider: LocalPathProviding,
         userNotificationController: UserNotificationControlling,
         application: ApplicationControlling,
         fileManager: FileManaging,
         environmentController: EnvironmentControlling,
         riskCalculationController: RiskCalculationControlling,
         keySetDownloadProcessor: KeySetDownloadProcessing) {
        self.networkController = networkController
        self.storageController = storageController
        self.applicationSignatureController = applicationSignatureController
        self.localPathProvider = localPathProvider
        self.userNotificationController = userNotificationController
        self.application = application
        self.fileManager = fileManager
        self.environmentController = environmentController
        self.riskCalculationController = riskCalculationController
        self.keySetDownloadProcessor = keySetDownloadProcessor
    }

    // MARK: - ExposureDataOperationProvider

    func processExposureKeySetsOperation(exposureManager: ExposureManaging,
                                         exposureDataController: ExposureDataController,
                                         configuration: ExposureConfiguration) -> ProcessExposureKeySetsDataOperationProtocol {

        return ProcessExposureKeySetsDataOperation(networkController: networkController,
                                                   storageController: storageController,
                                                   exposureManager: exposureManager,
                                                   localPathProvider: localPathProvider,
                                                   exposureDataController: exposureDataController,
                                                   configuration: configuration,
                                                   userNotificationController: userNotificationController,
                                                   application: application,
                                                   fileManager: fileManager,
                                                   environmentController: environmentController,
                                                   riskCalculationController: riskCalculationController)
    }

    func processPendingLabConfirmationUploadRequestsOperation(padding: Padding) -> ProcessPendingLabConfirmationUploadRequestsDataOperationProtocol {
        return ProcessPendingLabConfirmationUploadRequestsDataOperation(networkController: networkController,
                                                                        storageController: storageController,
                                                                        padding: padding)
    }

    func expiredLabConfirmationNotificationOperation() -> ExpiredLabConfirmationNotificationDataOperationProtocol {
        return ExpiredLabConfirmationNotificationDataOperation(storageController: storageController,
                                                               userNotificationController: userNotificationController)
    }

    func requestAppConfigurationOperation(identifier: String) -> RequestAppConfigurationDataOperationProtocol {
        return RequestAppConfigurationDataOperation(networkController: networkController,
                                                    storageController: storageController,
                                                    applicationSignatureController: applicationSignatureController,
                                                    appConfigurationIdentifier: identifier)
    }

    func requestExposureConfigurationOperation(identifier: String) -> RequestExposureConfigurationDataOperationProtocol {
        return RequestExposureConfigurationDataOperation(networkController: networkController,
                                                         storageController: storageController,
                                                         exposureConfigurationIdentifier: identifier)
    }

    func requestExposureKeySetsOperation(identifiers: [String]) -> RequestExposureKeySetsDataOperationProtocol {
        return RequestExposureKeySetsDataOperation(networkController: networkController,
                                                   storageController: storageController,
                                                   exposureKeySetIdentifiers: identifiers,
                                                   keySetDownloadProcessor: keySetDownloadProcessor)
    }

    var requestManifestOperation: RequestAppManifestDataOperationProtocol {
        return RequestAppManifestDataOperation(networkController: networkController,
                                               storageController: storageController)
    }

    var updateTreatmentPerspectiveDataOperation: UpdateTreatmentPerspectiveDataOperationProtocol {
        return UpdateTreatmentPerspectiveDataOperation(networkController: networkController,
                                                       storageController: storageController)
    }

    func requestLabConfirmationKeyOperation(padding: Padding) -> RequestLabConfirmationKeyDataOperationProtocol {
        return RequestLabConfirmationKeyDataOperation(networkController: networkController,
                                                      storageController: storageController,
                                                      padding: padding)
    }

    func uploadDiagnosisKeysOperation(diagnosisKeys: [DiagnosisKey],
                                      labConfirmationKey: LabConfirmationKey,
                                      padding: Padding) -> UploadDiagnosisKeysDataOperationProtocol {
        return UploadDiagnosisKeysDataOperation(networkController: networkController,
                                                storageController: storageController,
                                                diagnosisKeys: diagnosisKeys,
                                                labConfirmationKey: labConfirmationKey,
                                                padding: padding)
    }

    // MARK: - Private

    private let networkController: NetworkControlling
    private let storageController: StorageControlling
    private let applicationSignatureController: ApplicationSignatureControlling
    private let localPathProvider: LocalPathProviding
    private let userNotificationController: UserNotificationControlling
    private let application: ApplicationControlling
    private let fileManager: FileManaging
    private let environmentController: EnvironmentControlling
    private let riskCalculationController: RiskCalculationControlling
    private let keySetDownloadProcessor: KeySetDownloadProcessing
}

extension NetworkError {
    var asExposureDataError: ExposureDataError {
        switch self {
        case .invalidResponse:
            return .serverError
        case .serverNotReachable:
            return .networkUnreachable
        case .invalidRequest:
            return .internalError
        case .resourceNotFound:
            return .serverError
        case .responseCached:
            return .internalError
        case .serverError:
            return .serverError
        case .encodingError:
            return .internalError
        case .redirection:
            return .serverError
        case .errorConversionError:
            return .internalError
        }
    }
}

extension StoreError {
    var asExposureDataError: ExposureDataError {
        switch self {
        case .cannotEncode, .fileSystemError, .keychainError:
            return .internalError
        }
    }
}

extension ExposureManagerError {
    var asExposureDataError: ExposureDataError {
        switch self {
        case .bluetoothOff:
            return .inactive(.bluetoothOff)
        case .disabled, .restricted:
            return .inactive(.disabled)
        case .notAuthorized:
            return .notAuthorized
        case .internalTypeMismatch, .unknown, .rateLimited:
            return .internalError
        case .signatureValidationFailed:
            return .signatureValidationFailed
        }
    }
}

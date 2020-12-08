/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

final class ExposureDataOperationProviderImpl: ExposureDataOperationProvider {

    init(networkController: NetworkControlling,
         storageController: StorageControlling,
         applicationSignatureController: ApplicationSignatureControlling,
         localPathProvider: LocalPathProviding,
         userNotificationCenter: UserNotificationCenter,
         application: ApplicationControlling,
         fileManager: FileManaging) {
        self.networkController = networkController
        self.storageController = storageController
        self.applicationSignatureController = applicationSignatureController
        self.localPathProvider = localPathProvider
        self.userNotificationCenter = userNotificationCenter
        self.application = application
        self.fileManager = fileManager
    }

    // MARK: - ExposureDataOperationProvider

    func processExposureKeySetsOperation(exposureManager: ExposureManaging,
                                         configuration: ExposureConfiguration) -> ProcessExposureKeySetsDataOperation? {
        guard let exposureKeySetsStorageUrl = localPathProvider.path(for: .exposureKeySets) else {
            return nil
        }

        return ProcessExposureKeySetsDataOperation(networkController: networkController,
                                                   storageController: storageController,
                                                   exposureManager: exposureManager,
                                                   exposureKeySetsStorageUrl: exposureKeySetsStorageUrl,
                                                   configuration: configuration,
                                                   userNotificationCenter: userNotificationCenter,
                                                   application: application,
                                                   fileManager: fileManager)
    }

    func processPendingLabConfirmationUploadRequestsOperation(padding: Padding) -> ProcessPendingLabConfirmationUploadRequestsDataOperation {
        return ProcessPendingLabConfirmationUploadRequestsDataOperation(networkController: networkController,
                                                                        storageController: storageController,
                                                                        userNotificationCenter: userNotificationCenter,
                                                                        padding: padding)
    }

    func requestAppConfigurationOperation(identifier: String) -> RequestAppConfigurationDataOperation {
        return RequestAppConfigurationDataOperation(networkController: networkController,
                                                    storageController: storageController,
                                                    applicationSignatureController: applicationSignatureController,
                                                    appConfigurationIdentifier: identifier)
    }

    func requestExposureConfigurationOperation(identifier: String) -> RequestExposureConfigurationDataOperation {
        return RequestExposureConfigurationDataOperation(networkController: networkController,
                                                         storageController: storageController,
                                                         exposureConfigurationIdentifier: identifier)
    }

    func requestExposureKeySetsOperation(identifiers: [String]) -> RequestExposureKeySetsDataOperation {
        return RequestExposureKeySetsDataOperation(networkController: networkController,
                                                   storageController: storageController,
                                                   localPathProvider: localPathProvider,
                                                   exposureKeySetIdentifiers: identifiers)
    }

    var requestManifestOperation: RequestAppManifestDataOperation {
        return RequestAppManifestDataOperation(networkController: networkController,
                                               storageController: storageController)
    }

    var requestTreatmentPerspectiveDataOperation: RequestTreatmentPerspectiveDataOperation {
        return RequestTreatmentPerspectiveDataOperation(networkController: networkController,
                                                        storageController: storageController)
    }

    func requestLabConfirmationKeyOperation(padding: Padding) -> RequestLabConfirmationKeyDataOperation {
        return RequestLabConfirmationKeyDataOperation(networkController: networkController,
                                                      storageController: storageController,
                                                      padding: padding)
    }

    func uploadDiagnosisKeysOperation(diagnosisKeys: [DiagnosisKey],
                                      labConfirmationKey: LabConfirmationKey,
                                      padding: Padding) -> UploadDiagnosisKeysDataOperation {
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
    private let userNotificationCenter: UserNotificationCenter
    private let application: ApplicationControlling
    private let fileManager: FileManaging
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

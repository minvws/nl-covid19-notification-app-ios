/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import ExposureNotification
import Foundation

#if DEBUG || USE_DEVELOPMENT_MENU

    final class ExposureManagerOverrides {
        static var useTestDiagnosisKeys: Bool?
    }

#endif

final class ExposureManager: ExposureManaging, Logging {

    init(manager: ENManaging) {
        self.manager = manager
    }

    deinit {
        manager.invalidate()
    }

    // MARK: - ExposureManaging

    var authorizationStatus: ENAuthorizationStatus {
        return type(of: manager).authorizationStatus
    }

    func activate(completion: @escaping (ExposureManagerStatus) -> ()) {
        #if DEBUG
            assert(Thread.isMainThread)
        #endif

        manager.activate { [weak self] error in
            guard let strongSelf = self else {
                // Exposure Manager released before activation
                completion(.inactive(.unknown))

                return
            }

            if let error = error.map({ $0.asExposureManagerError }) {
                let authorisationStatus: ExposureManagerStatus = .inactive(error)

                completion(authorisationStatus)
                return
            }

            // successful initialisation
            let authorisationStatus = strongSelf.getExposureNotificationStatus()

            completion(authorisationStatus)
        }
    }

    func deactivate() {
        manager.setExposureNotificationEnabled(false) { error in
            if let error = error {
                self.logError("Error disabling `ExposureNotifications`: \(error.localizedDescription)")
            }
        }
    }

    func detectExposures(configuration: ExposureConfiguration,
                         diagnosisKeyURLs: [URL],
                         completion: @escaping (Result<ExposureDetectionSummary?, ExposureManagerError>) -> ()) {
        #if DEBUG
            assert(Thread.isMainThread)
        #endif

        self.manager.detectExposures(configuration: configuration.asExposureConfiguration,
                                     diagnosisKeyURLs: diagnosisKeyURLs)
        { summary, error in
            if let error = error.map({ $0.asExposureManagerError }) {
                completion(.failure(error))
                return
            }

            guard let summary = summary else {
                // call to api success - no exposure
                completion(.success(nil))
                return
            }

            completion(.success(summary))
        }
        .resume()
    }

    func getDiagnonisKeys(completion: @escaping (Result<[DiagnosisKey], ExposureManagerError>) -> ()) {
        #if DEBUG
            assert(Thread.isMainThread)
        #endif

        let retrieve: (@escaping ENGetDiagnosisKeysHandler) -> ()

        #if DEBUG || USE_DEVELOPER_MENU
            if let useTestDiagnosisKeys = ExposureManagerOverrides.useTestDiagnosisKeys, !useTestDiagnosisKeys {
                retrieve = manager.getDiagnosisKeys(completionHandler:)
            } else {
                retrieve = manager.getTestDiagnosisKeys(completionHandler:)
            }
        #else
            retrieve = manager.getDiagnosisKeys(completionHandler:)
        #endif

        retrieve { keys, error in
            if let error = error.map({ $0.asExposureManagerError }) {
                completion(.failure(error))
                return
            }

            guard let keys = keys else {
                // call is success, no keys
                completion(.success([]))
                return
            }

            // Convert keys to generic struct
            let diagnosisKeys = keys.map { diagnosisKey -> DiagnosisKey in
                return DiagnosisKey(keyData: diagnosisKey.keyData,
                                    rollingPeriod: diagnosisKey.rollingPeriod,
                                    rollingStartNumber: diagnosisKey.rollingStartNumber,
                                    transmissionRiskLevel: diagnosisKey.transmissionRiskLevel)
            }

            completion(.success(diagnosisKeys))
        }
    }

    func getExposureInfo(summary: ExposureDetectionSummary,
                         userExplanation: String,
                         completionHandler: @escaping ([ExposureInformation]?, ExposureManagerError?) -> ()) {
        #if DEBUG
            assert(Thread.isMainThread)
        #endif

        guard let summary = summary as? ENExposureDetectionSummary else {
            completionHandler(nil, .internalTypeMismatch)
            return
        }

        var explanation = userExplanation
        if userExplanation.last == "." {
            _ = explanation.removeLast()
        }

        _ = manager.getExposureInfo(summary: summary, userExplanation: explanation) { (info: [ENExposureInfo]?, error: Error?) in
            completionHandler(info, error.map { $0.asExposureManagerError })
        }
    }

    func setExposureNotificationEnabled(_ enabled: Bool, completion: @escaping (Result<(), ExposureManagerError>) -> ()) {
        manager.setExposureNotificationEnabled(enabled) { error in
            guard let error = error.map({ $0.asExposureManagerError }) else {
                completion(.success(()))
                return
            }

            completion(.failure(error))
        }
    }

    func isExposureNotificationEnabled() -> Bool {
        manager.exposureNotificationEnabled
    }

    func getExposureNotificationStatus() -> ExposureManagerStatus {
        let authorisationStatus = type(of: manager).authorizationStatus
        let result: ExposureManagerStatus

        switch authorisationStatus {
        case .authorized:
            switch manager.exposureNotificationStatus {
            case .active:
                result = .active
            case .bluetoothOff:
                result = .inactive(.bluetoothOff)
            case .disabled:
                result = .inactive(.disabled)
            case .restricted:
                result = .inactive(.restricted)
            default:
                result = .inactive(.unknown)
            }
        case .notAuthorized:
            result = .authorizationDenied
        case .unknown:
            result = .notAuthorized
        case .restricted:
            result = .inactive(.restricted)
        default:
            result = .inactive(.unknown)
        }

        logDebug("`getExposureNotificationStatus`: \(result)")
        return result
    }

    private let manager: ENManaging
}

extension Error {
    var asExposureManagerError: ExposureManagerError {
        if let error = self as? ENError {
            let status: ExposureManagerError

            switch error.code {
            case .bluetoothOff:
                status = .bluetoothOff
            case .restricted:
                status = .restricted
            case .notAuthorized:
                status = .notAuthorized
            case .notEnabled:
                status = .disabled
            case .rateLimited:
                status = .rateLimited
            default:
                status = .unknown
            }

            return status
        }

        return .unknown
    }
}

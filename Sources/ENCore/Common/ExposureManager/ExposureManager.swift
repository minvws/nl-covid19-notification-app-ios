/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CocoaLumberjackSwift
import ENFoundation
import ExposureNotification
import Foundation

#if DEBUG || USE_DEVELOPER_MENU

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
        if manager.exposureNotificationEnabled {
            manager.setExposureNotificationEnabled(false) { error in
                if let error = error {
                    self.logError("Error disabling `ExposureNotifications`: \(error.localizedDescription)")
                }
            }
        }
    }

    func detectExposures(configuration: ExposureConfiguration,
                         diagnosisKeyURLs: [URL],
                         completion: @escaping (Result<ExposureDetectionSummary?, ExposureManagerError>) -> ()) {
        #if DEBUG
            assert(Thread.isMainThread)
        #endif

        manager.detectExposures(configuration: configuration.asExposureConfiguration,
                                diagnosisKeyURLs: diagnosisKeyURLs) { summary, error in
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

    func getExposureWindows(summary: ExposureDetectionSummary, completion: @escaping (Result<[ExposureWindow]?, ExposureManagerError>) -> ()) {
        #if DEBUG
            assert(Thread.isMainThread)
        #endif

        guard let enSummary = summary as? ENExposureDetectionSummary else {
            completion(.failure(.internalTypeMismatch))
            return
        }

        manager.getExposureWindows(summary: enSummary) { windows, error in
            if let error = error.map({ $0.asExposureManagerError }) {
                completion(.failure(error))
                return
            }

            guard let windows = windows else {
                // call to api success - no exposure windows
                completion(.success(nil))
                return
            }

            completion(.success(windows))
        }.resume()
    }

    func getDiagnosisKeys(completion: @escaping (Result<[DiagnosisKey], ExposureManagerError>) -> ()) {
        #if DEBUG
            assert(Thread.isMainThread)
        #endif

        manager.getDiagnosisKeys(completionHandler:) { keys, error in
            if let error = error.map({ $0.asExposureManagerError }) {
                completion(.failure(error))
                return
            }

            guard let keys = keys else {
                // call is success, no keys
                if let ENAPIVersion = Bundle.main.object(forInfoDictionaryKey: "ENAPIVersion") as? Int,
                    ENAPIVersion == 2 {
                    self.logWarning("ExposureManager - `getDiagnosisKeys` - Using ENAPIVersion 2 but no keys available")
                }
                completion(.success([]))
                return
            }

            // Convert keys to generic struct
            let diagnosisKeys = keys.map { diagnosisKey -> DiagnosisKey in
                DiagnosisKey(keyData: diagnosisKey.keyData,
                             rollingPeriod: diagnosisKey.rollingPeriod,
                             rollingStartNumber: diagnosisKey.rollingStartNumber,
                             transmissionRiskLevel: diagnosisKey.transmissionRiskLevel)
            }

            completion(.success(diagnosisKeys))
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

        // iOS 14 returns unknown as authorizationStatus always
        let isiOS14OrHigher: Bool
        if #available(iOS 14, *) {
            isiOS14OrHigher = true
        } else {
            isiOS14OrHigher = false
        }

        logDebug("`getExposureNotificationStatus`. authorisationStatus: \(authorisationStatus.rawValue). exposureNotificationStatus: \(manager.exposureNotificationStatus.rawValue)")

        switch authorisationStatus {
        case .unknown where isiOS14OrHigher:
            fallthrough
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
        case .unknown:
            result = .notAuthorized
        case .notAuthorized:
            result = .authorizationDenied
        case .restricted:
            result = .inactive(.restricted)
        default:
            result = .inactive(.unknown)
        }

        logDebug("`getExposureNotificationStatus`: \(result)")
        return result
    }

    func setLaunchActivityHandler(activityHandler: @escaping ENActivityHandler) {
        manager.setLaunchActivityHandler { activityFlags in
            activityHandler(activityFlags)
        }
    }

    private let manager: ENManaging
}

extension Error {
    var asExposureManagerError: ExposureManagerError {
        if let error = self as? ExposureManagerError {
            return error
        }

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
            case .unsupported:
                // usually when receiving unsupported something is off with the signature validation
                status = .signatureValidationFailed
            default:
                DDLogDebug("🐞 `asExposureManagerError` raw error \(error.localizedDescription) \(error.errorCode)")
                status = .unknown
            }

            return status
        }

        return .unknown
    }
}

// Alternative callback approach used for Exposure Notifications on iOS 12.5

/// Activities that occurred while the app wasn't running.
struct ENActivityFlags: OptionSet {
    let rawValue: UInt32

    /// App launched to perform periodic operations.
    static let periodicRun = ENActivityFlags(rawValue: 1 << 2)
}

/// Invoked after the app is launched to report activities that occurred while the app wasn't running.
typealias ENActivityHandler = (ENActivityFlags) -> ()

extension ENManager: Logging {
    /// On iOS 12.5 only, this will ensure the app receives 3.5 minutes of background processing
    /// every 4 hours. This function is needed on iOS 12.5 because the BackgroundTask framework, used
    /// for Exposure Notifications background processing in iOS 13.5+ does not exist in iOS 12.
    func setLaunchActivityHandler(activityHandler: @escaping ENActivityHandler) {
        logDebug("ENManager.setLaunchActivityHandler() called")

        let proxyActivityHandler: @convention(block) (UInt32) -> () = { integerFlag in
            activityHandler(ENActivityFlags(rawValue: integerFlag))
        }

        logDebug("ENManager.setLaunchActivityHandler() proxyActivityHandler: \(String(describing: proxyActivityHandler))")

        setValue(proxyActivityHandler, forKey: "activityHandler")
    }
}

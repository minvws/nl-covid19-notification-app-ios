/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ExposureNotification
import Foundation

final class ExposureManager: ExposureManaging {

    init(manager: ENManaging) {
        self.manager = manager
    }

    deinit {
        manager.invalidate()
    }

    // MARK: - ExposureManaging

    func activate(completion: @escaping (ExposureManagerStatus) -> ()) {
        assert(Thread.isMainThread)

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

    func detectExposures(diagnosisKeyURLs: [URL], completion: @escaping (Result<ExposureDetectionSummary?, ExposureManagerError>) -> ()) {
        assert(Thread.isMainThread)

        let configuration = self.getExposureConfiguration()

        self.manager.detectExposures(configuration: configuration,
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
        assert(Thread.isMainThread)

        let retrieve: (@escaping ENGetDiagnosisKeysHandler) -> ()

        #if DEBUG
            retrieve = manager.getTestDiagnosisKeys(completionHandler:)
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
                         completionHandler: @escaping ([ExposureInformation]?, ExposureManagerError?) -> ()) -> Progress {
        assert(Thread.isMainThread)

        guard let summary = summary as? ENExposureDetectionSummary else {
            completionHandler(nil, .internalTypeMismatch)
            return Progress()
        }

        return manager.getExposureInfo(summary: summary, userExplanation: userExplanation) { (info: [ENExposureInfo]?, error: Error?) in
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

        switch authorisationStatus {
        case .authorized:
            switch manager.exposureNotificationStatus {
            case .active:
                return .active
            case .bluetoothOff:
                return .inactive(.bluetoothOff)
            case .disabled:
                return .inactive(.disabled)
            case .restricted:
                return .inactive(.restricted)
            default:
                return .inactive(.unknown)
            }
        case .notAuthorized:
            return .authorizationDenied
        case .unknown:
            return .notAuthorized
        case .restricted:
            return .inactive(.restricted)
        default:
            return .inactive(.unknown)
        }
    }

    /// temporary - hardcoded - function
    private func getExposureConfiguration() -> ENExposureConfiguration {

        let SEQUENTIAL_WEIGHTS: [NSNumber] = [1, 2, 3, 4, 5, 6, 7, 8]
        let EQUAL_WEIGHTS: [NSNumber] = [1, 1, 1, 1, 1, 1, 1, 1]

        let exposureConfiguration = ENExposureConfiguration()
        exposureConfiguration.minimumRiskScore = 1
        exposureConfiguration.attenuationLevelValues = SEQUENTIAL_WEIGHTS
        exposureConfiguration.daysSinceLastExposureLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.durationLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.transmissionRiskLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.metadata = ["attenuationDurationThresholds": [42, 56]]
        return exposureConfiguration
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
            default:
                status = .unknown
            }

            return status
        }

        return .unknown
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import ExposureNotification

enum ExposureManagerStatus {
    case notAvailable
    case updateOS
    case active
}

struct DiagnosisKey: Codable {
    let keyData: Data
    let rollingPeriod: UInt32
    let rollingStartNumber: UInt32
    let transmissionRiskLevel: UInt8
}

struct ExposureDetectionSummary {
    let attenuationDurations: [NSNumber]
    let daysSinceLastExposure: Int
    let matchedKeyCount: UInt64
    let maximumRiskScore: UInt8
    let metadata: [AnyHashable : Any]?
}

enum ENFrameworkStatus : Int {
    case unknown = 0
    case active = 1
    case disabled = 2
    case bluetoothOff = 3
    case restricted = 4
}


/// @mockable
protocol ExposureManaging {
    typealias ErrorHandler = (Error?) -> Void
    typealias GetDiagnosisKeysHandler = (Result<[DiagnosisKey], Error>) -> Void
    typealias DetectExposuresHandler = (Result<ExposureDetectionSummary?, Error>) -> Void
    
    func detectExposures(_ urls:[URL], completionHandler: @escaping DetectExposuresHandler)
    func getDiagnonisKeys(completionHandler: @escaping GetDiagnosisKeysHandler)
    func setExposureNotificationEnabled(_ enabled: Bool, completionHandler: @escaping ErrorHandler)
    func isExposureNotificationEnabled() -> Bool
    func getExposureNotificationStatus() -> ENFrameworkStatus
    
}

@available(iOS 13.5, *)
class ExposureManager: ExposureManaging {
    
    private let manager = ENManager()
    
    init() {
        manager.activate { _ in
            if ENManager.authorizationStatus == .authorized && !self.manager.exposureNotificationEnabled {
                self.manager.setExposureNotificationEnabled(true) { _ in
                    // No error handling for attempts to enable on launch
                }
            }
        }
    }
    
    func detectExposures(_ urls: [URL], completionHandler: @escaping DetectExposuresHandler) {
        self.manager.detectExposures(configuration: self.getExposureConfiguration(), diagnosisKeyURLs: urls) { summary, error in
            
            if let error = error {
                completionHandler(.failure(error))
            } else {
                
                guard let summary = summary else {
                    // call to api success bu no exposure
                    completionHandler(.success(nil))
                    return
                }
                
                // convert to generic
                let exposureDetectionSummary = ExposureDetectionSummary(
                    attenuationDurations: summary.attenuationDurations,
                    daysSinceLastExposure: summary.daysSinceLastExposure,
                    matchedKeyCount: summary.matchedKeyCount,
                    maximumRiskScore: summary.maximumRiskScore,
                    metadata: summary.metadata)
                
                completionHandler(.success(exposureDetectionSummary))
            }
        }
    }
    
    func getDiagnonisKeys(completionHandler: @escaping GetDiagnosisKeysHandler) {
        self.manager.getDiagnosisKeys { keys, error in

            if let error = error {
                completionHandler(.failure(error))
            } else {
                
                guard let keys = keys else {
                    // call is success, no keys
                    completionHandler(.success([DiagnosisKey]()))
                    return
                }
                
                // Convert keys to something generic
                let diagnosisKeys = keys.compactMap { diagnosisKey -> DiagnosisKey? in
                    return DiagnosisKey(keyData: diagnosisKey.keyData,
                                          rollingPeriod: diagnosisKey.rollingPeriod,
                                          rollingStartNumber: diagnosisKey.rollingStartNumber,
                                          transmissionRiskLevel: diagnosisKey.transmissionRiskLevel)
                }
                completionHandler(.success(diagnosisKeys))
            }

        }
    }
    
    func setExposureNotificationEnabled(_ enabled: Bool, completionHandler: @escaping ErrorHandler) {
        self.manager.setExposureNotificationEnabled(enabled, completionHandler: completionHandler)
    }
    
    func isExposureNotificationEnabled() -> Bool {
        self.manager.exposureNotificationEnabled
    }
    
    func getExposureNotificationStatus() -> ENFrameworkStatus {
        let status = self.manager.exposureNotificationStatus.rawValue
        return ENFrameworkStatus.init(rawValue: status) ?? ENFrameworkStatus.unknown
    }
    
    /// temporary - hardcoded - function
    private func getExposureConfiguration() -> ENExposureConfiguration {
        
        let SEQUENTIAL_WEIGHTS :[NSNumber] = [1,2,3,4,5,6,7,8]
        let EQUAL_WEIGHTS :[NSNumber] = [1,1,1,1,1,1,1,1]
        
        let exposureConfiguration = ENExposureConfiguration()
        exposureConfiguration.minimumRiskScore = 1
        exposureConfiguration.attenuationLevelValues = SEQUENTIAL_WEIGHTS
        exposureConfiguration.daysSinceLastExposureLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.durationLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.transmissionRiskLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.metadata = ["attenuationDurationThresholds": [42, 56]]
        return exposureConfiguration
    }
    
}

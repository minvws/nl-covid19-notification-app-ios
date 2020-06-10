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

struct ENDiagnosisKey: Codable {
    let keyData: Data
    let rollingPeriod: UInt32
    let rollingStartNumber: UInt32
    let transmissionRiskLevel: UInt8
}

/// @mockable
protocol ExposureManaging {
    typealias GetDiagnosisKeysHandler = (Result<[ENDiagnosisKey], Error>) -> Void
    
    func detectExposures()
    func getDiagnonisKeys(completionHandler: @escaping GetDiagnosisKeysHandler)
    func setExposureNotificationEnabled(enabled: Bool)
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
    
    func detectExposures() {
        
    }
    
    func getDiagnonisKeys(completionHandler: @escaping GetDiagnosisKeysHandler) {
        self.manager.getDiagnosisKeys { keys, error in

            if let error = error {
                completionHandler(.failure(error))
            } else {
                // Convert keys to something generic
                let diagnosisKeys = keys!.compactMap { diagnosisKey -> ENDiagnosisKey? in
                    return ENDiagnosisKey(keyData: diagnosisKey.keyData,
                                          rollingPeriod: diagnosisKey.rollingPeriod,
                                          rollingStartNumber: diagnosisKey.rollingStartNumber,
                                          transmissionRiskLevel: diagnosisKey.transmissionRiskLevel)
                }
                completionHandler(.success(diagnosisKeys))
            }

        }
    }
    
    func setExposureNotificationEnabled(enabled: Bool) {
        
    }
    
}

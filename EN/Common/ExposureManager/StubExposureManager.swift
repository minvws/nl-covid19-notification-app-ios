/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// Stub implementation of ExposureManaging to
/// use when in simulator
final class StubExposureManager: ExposureManaging {
    
    func activate(completion: @escaping (ExposureManagerAuthorisationStatus) -> Void) {
        // activation always succeed in stub-land
        completion(.active)
    }
    
    func getExposureNotificationAuthorisationStatus() -> ExposureManagerAuthorisationStatus {
        return isExposureNotificationEnabled() ? .active : .inactive(.unknown)
    }
    
    func isExposureNotificationEnabled() -> Bool {
        return exposureNotificationEnabled
    }
    
    func setExposureNotificationEnabled(_ enabled: Bool, completion: @escaping (Result<(), ExposureManagerError>) -> Void) {
        exposureNotificationEnabled = enabled
        
        completion(.success(()))
    }
    
    func detectExposures(diagnosisKeyURLs: [URL], completion: @escaping (Result<ExposureDetectionSummary?, ExposureManagerError>) -> Void) {
        // fake exposure
        
        let summary = ExposureDetectionSummary(
            attenuationDurations: [15],
            daysSinceLastExposure: 1,
            matchedKeyCount: 2,
            maximumRiskScore: 3,
            metadata: [AnyHashable:Any]()
        )
        
        completion(.success(summary))
    }
    
    func getDiagnonisKeys(completion: @escaping (Result<[DiagnosisKey], ExposureManagerError>) -> Void) {
        completion(.success([]))
    }
    
    func setExposureNotificationEnabled(enabled: Bool) {
        self.exposureNotificationEnabled = enabled
    }
    
    // return whether exposureNotifications should be enabled or not
    private var exposureNotificationEnabled = false
}

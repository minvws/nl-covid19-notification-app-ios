/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

class ExposureStubManager: ExposureManaging {
    
    func getExposureNotificationStatus() -> ENFrameworkStatus {
        return ENFrameworkStatus.active
    }
    
    private var exposureNotificationEnabled: Bool = false
    
    func isExposureNotificationEnabled() -> Bool {
        return exposureNotificationEnabled
    }
    
    
    func setExposureNotificationEnabled(_ enabled: Bool, completionHandler: @escaping ErrorHandler) {
        self.exposureNotificationEnabled = enabled
        completionHandler(nil)
    }
    
    func detectExposures(_ urls: [URL], completionHandler: @escaping DetectExposuresHandler) {
        completionHandler(.success(ExposureDetectionSummary(
            attenuationDurations: [15],
            daysSinceLastExposure: 1,
            matchedKeyCount: 2,
            maximumRiskScore: 3,
            metadata: [AnyHashable:Any]()
        )))
    }
    
    func getDiagnonisKeys(completionHandler: @escaping GetDiagnosisKeysHandler) {
        let keys = [DiagnosisKey]()
        completionHandler(.success(keys))
    }
    
    func setExposureNotificationEnabled(enabled: Bool) {
        
    }
    
    
}

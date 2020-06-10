/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

class ExposureStubManager: ExposureManaging {
    
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
    
    func getDiagnonisKeys() {
        
    }
    
    func setExposureNotificationEnabled(enabled: Bool) {
        
    }
    
    
}

/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

class ExposureStubManager: ExposureManaging {
    
    func getDiagnonisKeys(completionHandler: @escaping GetDiagnosisKeysHandler) {
        let keys = [ENDiagnosisKey]()
        completionHandler(.success(keys))
    }
    
    func detectExposures() {
        
    }
    
    func getDiagnonisKeys() {
        
    }
    
    func setExposureNotificationEnabled(enabled: Bool) {
        
    }
    
    
}

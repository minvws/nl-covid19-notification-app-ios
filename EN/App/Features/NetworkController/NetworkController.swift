/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

final class NetworkController: NetworkControlling {
    
    func getManifest() -> Manifest {
        return Manifest(exposureKeySets: [], resourceBundle: "", riskCalculationParameters: "", appConfig: "")
    }
    
    func getExposureKeySet() -> [URL] {
        return [URL]()
    }
    
    func getResourceBundle() {
        
    }
    
    func getRiskCalculationParameters() -> RiskCalculationParameters {
        return RiskCalculationParameters(release: "", minimumRiskScore: 1, attenuationScores: [1], daysSinceLastExposureScores: [1], durationScores: [1], transmissionRiskScores: [1], durationAtAttenuationThresholds: [1])
    }
    
    func getAppConfig() -> AppConfig {
        return AppConfig(version: 1, manifestFrequency: 1, decoyProbability: 1)
    }
    
    func register() {
        
    }
    
    func postKeys() {
        
    }
    
    func postStopKeys() {
        
    }
    
    
     
    init(networkManager:NetworkManaging) {
        self.networkManager = networkManager
    }
    
    private let networkManager:NetworkManaging
}

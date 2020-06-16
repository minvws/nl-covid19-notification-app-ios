/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation


/// @mockable
protocol NetworkManaging {
    
    // MARK: CDN
    func getManifest(completion: @escaping (Result<Manifest, Error>) -> Void)
    func getAppConfig(appConfig:String, completion: @escaping (Error?) -> Void)
    func getRiskCalculationParameters(appConfig:String, completion: @escaping (Error?) -> Void)
    func getDiagnosisKeys(_ id: String, completion: @escaping (Result<ExposureKeySet, Error>) -> Void)
    
    // MARK: Enrollment
    func postRegister(register: Register, completion: @escaping (Result<LabInformation, Error>) -> Void)
    func postKeys(diagnosisKeys:DiagnosisKeys, completion: @escaping (Error?) -> Void)
    func stopKeys(diagnosisKeys:DiagnosisKeys, completion: @escaping (Error?) -> Void)
}
    
/// @mockable
protocol NetworkManagerBuildable {
    /// Builds an ExposureManager instance.
    /// Returns nil if the OS does not support Exposure Notifications
    func build() -> NetworkManaging
}

final class NetworkManagerBuilder: Builder<EmptyDependency>, NetworkManagerBuildable {
    func build() -> NetworkManaging {
        return NetworkManager(configuration: .development)
    }
    
    
}

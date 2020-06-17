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

    func getManifest(completion: @escaping (Result<Manifest, Error>) -> ())
    func getAppConfig(appConfig: String, completion: @escaping (Result<AppConfig, Error>) -> ())
    func getRiskCalculationParameters(appConfig: String, completion: @escaping (Result<RiskCalculationParameters, Error>) -> ())
    func getDiagnosisKeys(_ id: String, completion: @escaping (Result<ExposureKeySet, Error>) -> ())

    // MARK: Enrollment

    func postRegister(register: Register, completion: @escaping (Result<LabInformation, Error>) -> ())
    func postKeys(diagnosisKeys: DiagnosisKeys, completion: @escaping (Error?) -> ())
    func postStopKeys(diagnosisKeys: DiagnosisKeys, completion: @escaping (Error?) -> ())
}

/// @mockable
protocol NetworkManagerBuildable {
    func build() -> NetworkManaging
}

final class NetworkManagerBuilder: Builder<EmptyDependency>, NetworkManagerBuildable {
    func build() -> NetworkManaging {
        #if DEBUG
            let configuration: NetworkConfiguration = .development
        #else
            let configuration: NetworkConfiguration = .production
        #endif

        return NetworkManager(configuration: configuration)
    }
}

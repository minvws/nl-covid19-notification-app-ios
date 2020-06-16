/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation


protocol NetworkControlling {
    
    // MARK: - Calls for the background manager, should be queued
    func getManifest(completion: @escaping (Result<Manifest, Error>) -> ())
    func getExposureKeySet(exposureKeySet:String, completion: @escaping (Result<[URL], Error>) -> ())
    func getResourceBundle()
    func getRiskCalculationParameters(appConfig:String)
    func getAppConfig() -> AppConfig
    
    func postStopKeys()
    
    // MARK: - Post requests
    func register()
    func postKeys(diagnosisKeys:DiagnosisKeys)
}

/// @mockable
protocol NetworkControllerBuildable {
    /// Builds NetworkController
    ///
    /// - Parameter listener: Listener of created NetworkController
    func build() -> NetworkControlling
}


private final class NetworkControllerDependencyProvider: DependencyProvider<EmptyDependency> {
    lazy var networkManager: NetworkManaging = {
        return NetworkManagerBuilder().build()
    }()
}

final class NetworkControllerBuilder: Builder<EmptyDependency>, NetworkControllerBuildable {
    
    func build() -> NetworkControlling {
        let provider = NetworkControllerDependencyProvider(dependency: dependency)
        return NetworkController(networkManager: provider.networkManager)
    }
}

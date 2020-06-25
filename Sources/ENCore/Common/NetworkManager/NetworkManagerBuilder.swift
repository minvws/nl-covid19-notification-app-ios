/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum NetworkError: Error {
    case invalidRequest
    case serverNotReachable
    case invalidResponse
    case responseCached
    case serverError
    case resourceNotFound
    case encodingError
}

/// @mockable
protocol NetworkManaging {

    // MARK: CDN

    func getManifest(completion: @escaping (Result<Manifest, NetworkError>) -> ())
    func getAppConfig(appConfig: String, completion: @escaping (Result<AppConfig, NetworkError>) -> ())
    func getRiskCalculationParameters(identifier: String, completion: @escaping (Result<RiskCalculationParameters, NetworkError>) -> ())
    func getExposureKeySet(identifier: String, completion: @escaping (Result<URL, NetworkError>) -> ())

    // MARK: Enrollment

    func postRegister(request: RegisterRequest, completion: @escaping (Result<LabInformation, NetworkError>) -> ())
    func postKeys(request: PostKeysRequest, signature: String, completion: @escaping (NetworkError?) -> ())
    func postStopKeys(request: PostKeysRequest, signature: String, completion: @escaping (NetworkError?) -> ())
}

/// @mockable
protocol NetworkManagerBuildable {
    func build() -> NetworkManaging
}

protocol NetworkManagerDependency {
    var networkConfigurationProvider: NetworkConfigurationProvider { get }
}

private final class NetworkManagerDependencyProvider: DependencyProvider<NetworkManagerDependency> {
    lazy var responseHandlerProvider: NetworkResponseHandlerProvider = {
        return NetworkResponseHandlerProviderBuilder().build()
    }()
}

final class NetworkManagerBuilder: Builder<NetworkManagerDependency>, NetworkManagerBuildable {
    func build() -> NetworkManaging {

        let dependencyProvider = NetworkManagerDependencyProvider(dependency: dependency)

        return NetworkManager(configurationProvider: dependencyProvider.dependency.networkConfigurationProvider,
                              responseHandlerProvider: dependencyProvider.responseHandlerProvider)
    }
}

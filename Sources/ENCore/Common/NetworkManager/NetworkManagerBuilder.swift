/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

enum NetworkError: Error {
    case invalidRequest
    case serverNotReachable
    case invalidResponse
    case responseCached
    case serverError
    case resourceNotFound
    case encodingError
    case redirection
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
    var storageController: StorageControlling { get }
}

private final class NetworkManagerDependencyProvider: DependencyProvider<NetworkManagerDependency> {
    lazy var responseHandlerProvider: NetworkResponseHandlerProvider = {
        return NetworkResponseHandlerProviderBuilder().build()
    }()

    var session: URLSession {

        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown build"

        var sysinfo = utsname()
        uname(&sysinfo)
        let model = String(bytes: Data(bytes: &sysinfo.machine,
                                       count: Int(_SYS_NAMELEN)),
                           encoding: .ascii)?
            .trimmingCharacters(in: .controlCharacters) ?? "Unknown model"

        let systemVersion = UIDevice().systemVersion

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["User-Agent": "CoronaMelder/(\(buildNumber) (\(model) iOS (\(systemVersion)"]

        return URLSession(configuration: configuration,
                          delegate: sessionDelegate,
                          delegateQueue: OperationQueue.main)
    }

    var sessionDelegate: URLSessionDelegate? {
        return NetworkManagerURLSessionDelegate(configurationProvider: dependency.networkConfigurationProvider)
    }
}

final class NetworkManagerBuilder: Builder<NetworkManagerDependency>, NetworkManagerBuildable {
    func build() -> NetworkManaging {

        let dependencyProvider = NetworkManagerDependencyProvider(dependency: dependency)

        return NetworkManager(configurationProvider: dependencyProvider.dependency.networkConfigurationProvider,
                              responseHandlerProvider: dependencyProvider.responseHandlerProvider,
                              storageController: dependencyProvider.dependency.storageController,
                              session: dependencyProvider.session,
                              sessionDelegate: dependencyProvider.sessionDelegate)
    }
}

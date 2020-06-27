/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

/// @mockable
protocol NetworkControlling {
    var applicationManifest: AnyPublisher<ApplicationManifest, NetworkError> { get }

    func applicationConfiguration(identifier: String) -> AnyPublisher<ApplicationConfiguration, NetworkError>
    func exposureRiskConfigurationParameters(identifier: String) -> AnyPublisher<ExposureRiskConfiguration, NetworkError>
    func fetchExposureKeySet(identifier: String) -> AnyPublisher<(String, URL), NetworkError>

    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, NetworkError>
    func postKeys(keys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), NetworkError>

    func startObservingNetworkReachability()
    func stopObservingNetworkReachability()
}

/// @mockable
protocol NetworkControllerBuildable {
    /// Builds NetworkController
    ///
    /// - Parameter listener: Listener of created NetworkController
    func build() -> NetworkControlling
}

protocol NetworkControllerDependency {
    var networkConfigurationProvider: NetworkConfigurationProvider { get }
    var storageController: StorageControlling { get }
    var mutableNetworkStatusStream: MutableNetworkStatusStreaming { get }
}

private final class NetworkControllerDependencyProvider: DependencyProvider<NetworkControllerDependency>, NetworkManagerDependency {
    lazy var networkManager: NetworkManaging = {
        return NetworkManagerBuilder(dependency: self).build()
    }()

    var cryptoUtility: CryptoUtility {
        return CryptoUtilityBuilder().build()
    }

    var networkConfigurationProvider: NetworkConfigurationProvider {
        return dependency.networkConfigurationProvider
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }
}

final class NetworkControllerBuilder: Builder<NetworkControllerDependency>, NetworkControllerBuildable {

    func build() -> NetworkControlling {
        let dependencyProvider = NetworkControllerDependencyProvider(dependency: dependency)

        return NetworkController(networkManager: dependencyProvider.networkManager,
                                 cryptoUtility: dependencyProvider.cryptoUtility,
                                 mutableNetworkStatusStream: dependencyProvider.dependency.mutableNetworkStatusStream)
    }
}

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
    func applicationConfiguration(identifier: String) -> Future<ApplicationConfiguration, NetworkError>

    var applicationManifest: Future<ApplicationManifest, NetworkError> { get }
    var exposureKeySetProvider: Future<ExposureKeySetProvider, NetworkError> { get }
    var exposureRiskCalculationParameters: Future<ExposureRiskCalculationParameters, NetworkError> { get }

    func fetchExposureKeySet(identifier: String) -> Future<ExposureKeySetHolder, NetworkError>

    var resourceBundle: Future<ResourceBundle, NetworkError> { get }

    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, NetworkError>
    func postKeys(keys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), NetworkError>
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
}

final class NetworkControllerBuilder: Builder<NetworkControllerDependency>, NetworkControllerBuildable {

    func build() -> NetworkControlling {
        let dependencyProvider = NetworkControllerDependencyProvider(dependency: dependency)

        return NetworkController(networkManager: dependencyProvider.networkManager,
                                 cryptoUtility: dependencyProvider.cryptoUtility)
    }
}

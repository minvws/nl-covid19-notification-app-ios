/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

enum NetworkError: Error {
    case serverNotReachable
}

protocol NetworkControlling {
    var exposureKeySetProvider: Future<ExposureKeySetProvider, NetworkError> { get }
    var exposureRiskCalculationParameters: Future<ExposureRiskCalculationParameters, NetworkError> { get }
    var resourceBundle: Future<ResourceBundle, NetworkError> { get }
}

/// @mockable
protocol NetworkControllerBuildable {
    /// Builds NetworkController
    ///
    /// - Parameter listener: Listener of created NetworkController
    func build() -> NetworkControlling
}

protocol NetworkControllerDependency {
    var storageController: StorageControlling { get }
}

private final class NetworkControllerDependencyProvider: DependencyProvider<NetworkControllerDependency> {
    lazy var networkManager: NetworkManaging = {
        return NetworkManagerBuilder().build()
    }()
}

final class NetworkControllerBuilder: Builder<NetworkControllerDependency>, NetworkControllerBuildable {

    func build() -> NetworkControlling {

        let dependencyProvider = NetworkControllerDependencyProvider(dependency: dependency)
        return NetworkController(
            networkManager: dependencyProvider.networkManager,
            storageController: dependencyProvider.dependency.storageController)
    }
}

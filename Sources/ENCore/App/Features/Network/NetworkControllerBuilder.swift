/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

/// @mockable(history:fetchExposureKeySet=true)
protocol NetworkControlling {
    var applicationManifest: Single<ApplicationManifest> { get }

    func treatmentPerspective(identifier: String) -> Single<TreatmentPerspective>

    func applicationConfiguration(identifier: String) -> Single<ApplicationConfiguration>

    func exposureRiskConfigurationParameters(identifier: String) -> Single<ExposureRiskConfiguration>
    func fetchExposureKeySet(identifier: String, useSignatureFallback: Bool) -> Single<(String, URL)>

    func requestLabConfirmationKey(padding: Padding) -> Single<LabConfirmationKey>
    func postKeys(keys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey, padding: Padding) -> Completable
    func stopKeys(padding: Padding) -> Completable
}

/// @mockable
protocol NetworkControllerBuildable {
    /// Builds NetworkController
    ///
    /// - Parameter listener: Listener of created NetworkController
    func build() -> NetworkControlling
}

protocol NetworkControllerDependency {
    var cryptoUtility: CryptoUtility { get }
    var networkConfigurationProvider: NetworkConfigurationProvider { get }
    var storageController: StorageControlling { get }
}

private final class NetworkControllerDependencyProvider: DependencyProvider<NetworkControllerDependency>, NetworkManagerDependency {
    lazy var networkManager: NetworkManaging = {
        return NetworkManagerBuilder(dependency: self).build()
    }()

    var networkConfigurationProvider: NetworkConfigurationProvider {
        return dependency.networkConfigurationProvider
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }

    var localPathProvider: LocalPathProviding {
        LocalPathProvider()
    }
}

final class NetworkControllerBuilder: Builder<NetworkControllerDependency>, NetworkControllerBuildable {

    func build() -> NetworkControlling {
        let dependencyProvider = NetworkControllerDependencyProvider(dependency: dependency)

        return NetworkController(networkManager: dependencyProvider.networkManager,
                                 cryptoUtility: dependencyProvider.dependency.cryptoUtility)
    }
}

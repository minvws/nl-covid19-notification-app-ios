/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import RxSwift

/// @mockable
protocol NetworkControlling {
    var applicationManifest: Observable<ApplicationManifest> { get }

    func treatmentPerspective(identifier: String) -> Observable<TreatmentPerspective>

    func applicationConfiguration(identifier: String) -> Observable<ApplicationConfiguration>

    func exposureRiskConfigurationParameters(identifier: String) -> Observable<ExposureRiskConfiguration>
    func fetchExposureKeySet(identifier: String) -> Observable<(String, URL)>

    func requestLabConfirmationKey(padding: Padding) -> Observable<LabConfirmationKey>
    func postKeys(keys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey, padding: Padding) -> Observable<()>
    func stopKeys(padding: Padding) -> Observable<()>
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
}

final class NetworkControllerBuilder: Builder<NetworkControllerDependency>, NetworkControllerBuildable {

    func build() -> NetworkControlling {
        let dependencyProvider = NetworkControllerDependencyProvider(dependency: dependency)

        return NetworkController(networkManager: dependencyProvider.networkManager,
                                 cryptoUtility: dependencyProvider.dependency.cryptoUtility)
    }
}

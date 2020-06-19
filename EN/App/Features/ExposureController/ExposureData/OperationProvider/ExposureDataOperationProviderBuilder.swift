/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine

protocol ExposureDataOperation {
    associatedtype Result
    associatedtype Error: Swift.Error

    func execute() -> AnyPublisher<Result, Error>
}

/// @mockable
protocol ExposureDataOperationProvider {
    var requestLabConfirmationKeyOperation: RequestLabConfirmationKeyDataOperation { get }
}

protocol ExposureDataOperationProviderBuildable {
    func build() -> ExposureDataOperationProvider
}

protocol ExposureDataOperationProviderDependency {
    var networkController: NetworkControlling { get }
    var storageController: StorageControlling { get }
}

private final class ExposureDataOperationProviderDependencyProvider: DependencyProvider<ExposureDataOperationProviderDependency> {}

final class ExposureDataOperationProviderBuilder: Builder<ExposureDataOperationProviderDependency>, ExposureDataOperationProviderBuildable {
    func build() -> ExposureDataOperationProvider {
        let dependencyProvider = ExposureDataOperationProviderDependencyProvider(dependency: dependency)

        return ExposureDataOperationProviderImpl(networkController: dependencyProvider.dependency.networkController,
                                                 storageController: dependencyProvider.dependency.storageController)
    }
}

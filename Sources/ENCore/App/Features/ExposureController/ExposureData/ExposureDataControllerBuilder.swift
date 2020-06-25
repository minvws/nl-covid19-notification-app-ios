/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

enum ExposureDataError: Error {
    case networkUnreachable
    case serverError
    case internalError
    case inactive(ExposureStateInactiveState)
    case notAuthorized
}

/// @mockable
protocol ExposureDataControlling {
    // MARK: - Operations

    func scheduleOperations()

    // MARK: - Exposure Detection

    func fetchAndProcessExposureKeySets(exposureManager: ExposureManaging) -> AnyPublisher<(), ExposureDataError>
    var lastExposure: ExposureReport? { get }
    func removeLastExposure() -> Future<(), Never>

    // MARK: - Lab Flow

    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, ExposureDataError>
    func upload(diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), ExposureDataError>
}

protocol ExposureDataControllerBuildable {
    func build() -> ExposureDataControlling
}

protocol ExposureDataControllerDependency {
    var networkController: NetworkControlling { get }
    var storageController: StorageControlling { get }
}

private final class ExposureDataControllerDependencyProvider: DependencyProvider<ExposureDataControllerDependency>, ExposureDataOperationProviderDependency {

    // MARK: - ExposureDataOperationProviderDependency

    var networkController: NetworkControlling {
        return dependency.networkController
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }

    // MARK: - Private Dependencies

    var operationProvider: ExposureDataOperationProvider {
        return ExposureDataOperationProviderBuilder(dependency: self).build()
    }
}

final class ExposureDataControllerBuilder: Builder<ExposureDataControllerDependency>, ExposureDataControllerBuildable {
    func build() -> ExposureDataControlling {
        let dependencyProvider = ExposureDataControllerDependencyProvider(dependency: dependency)

        return ExposureDataController(operationProvider: dependencyProvider.operationProvider,
                                      storageController: dependencyProvider.storageController)
    }
}

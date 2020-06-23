/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

struct ApplicationConfiguration {
    let version: Int
    let manifestFrequency: Int
    let decoyProbability: Int
}

final class UpdateAppConfigDataOperation: ExposureDataOperation {
    typealias Result = ApplicationConfiguration

    private let networkController: NetworkControlling
    private let storageController: StorageControlling

    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        return Fail(error: ExposureDataError.internalError).eraseToAnyPublisher()
    }
}

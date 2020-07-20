/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

final class RequestStopKeysDataOperation: ExposureDataOperation {

    init(networkController: NetworkControlling, padding: Padding) {
        self.networkController = networkController
        self.padding = padding
    }

    // MARK: - ExposureDataOperation

    func execute() -> AnyPublisher<(), ExposureDataError> {
        return networkController
            .stopKeys(padding: padding)
            .mapError { (error: NetworkError) -> ExposureDataError in error.asExposureDataError }
            .share()
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private let networkController: NetworkControlling
    private let padding: Padding
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

final class ExposureDataController: ExposureDataControlling {

    init(networkController: NetworkControlling) {
        self.networkController = networkController
    }

    // MARK: - ExposureDataControlling

    func fetchAndProcessExposureKeySets() -> Future<(), Never> {
        return Future { promise in
            promise(.success(()))
        }
    }

    // MARK: - Private

    private let networkController: NetworkControlling
}

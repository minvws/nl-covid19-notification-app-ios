/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

final class NetworkController: NetworkControlling {

    // MARK: - NetworkControlling

    var exposureKeySetProvider: Future<ExposureKeySetProvider, NetworkError> {
        return Future { promise in
            promise(.failure(.serverNotReachable))
        }
    }

    var exposureRiskCalculationParameters: Future<ExposureRiskCalculationParameters, NetworkError> {
        return Future { promise in
            promise(.failure(.serverNotReachable))
        }
    }

    var resourceBundle: Future<ResourceBundle, NetworkError> {
        return Future { promise in
            promise(.failure(.serverNotReachable))
        }
    }

    private func updateWhenRequired(includeResources: Bool) -> Future<(), NetworkError> {
        return Future { promise in
            // TODO: Check if manifest, check if up-to-date, otherwise download
            // TODO: Check if new exposure keys, if any, download and store them
            // TODO: If includeResources = true, download any resources if needed
            //       Don't do this when in the background

            promise(.success(()))
        }
    }

    init(networkManager: NetworkManaging,
         storageController: StorageControlling) {
        self.networkManager = networkManager
        self.storageController = storageController
    }

    private let networkManager: NetworkManaging
    private let storageController: StorageControlling
}

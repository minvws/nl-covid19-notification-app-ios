/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift

/// @mockable
protocol RequestDashboardDataOperationProtocol {
    func execute() -> Single<DashboardData>
}

final class RequestDashboardDataOperation: RequestDashboardDataOperationProtocol, Logging {
    init(networkController: NetworkControlling,
         storageController: StorageControlling) {
        self.networkController = networkController
        self.storageController = storageController
    }

    func execute() -> Single<DashboardData> {

        let dashboardSingle = Single<DashboardData>.create { observer in

            self.logDebug("Getting fresh manifest from network")

            return self.networkController
                .dashboardData
                .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .catch { throw $0.asExposureDataError }
                .subscribe(observer)
        }

        return dashboardSingle.subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }

    // MARK: - Private

    private let defaultRefreshFrequency = 60 * 4 // 4 hours
    private let networkController: NetworkControlling
    private let storageController: StorageControlling
}

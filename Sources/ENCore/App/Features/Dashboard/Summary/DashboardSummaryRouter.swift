/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol DashboardSummaryViewControllable: ViewControllable {
    var router: DashboardSummaryRouting? { get set }
}

final class DashboardSummaryRouter: Router<DashboardSummaryViewControllable>, DashboardSummaryRouting {

    // MARK: - Initialisation

    init(listener: DashboardSummaryListener,
         viewController: DashboardSummaryViewControllable) {
        self.listener = listener

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - Private

    private weak var listener: DashboardSummaryListener?
}

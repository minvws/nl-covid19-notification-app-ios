/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol DashboardDetailViewControllable: ViewControllable {
    var router: DashboardDetailRouting? { get set }
}

final class DashboardDetailRouter: Router<DashboardDetailViewControllable>, DashboardDetailRouting {

    // MARK: - Initialisation

    init(listener: DashboardDetailListener,
         viewController: DashboardDetailViewControllable) {
        self.listener = listener

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - Private

    private weak var listener: DashboardDetailListener?
}

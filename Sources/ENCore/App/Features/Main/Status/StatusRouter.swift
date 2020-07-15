/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol StatusViewControllable: ViewControllable {
    var router: StatusRouting? { get set }
}

final class StatusRouter: Router<StatusViewControllable>, StatusRouting {

    // MARK: - Initialisation

    init(listener: StatusListener,
         viewController: StatusViewControllable) {
        self.listener = listener

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - Private

    private weak var listener: StatusListener?
}

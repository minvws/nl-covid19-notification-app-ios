/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol PauseConfirmationViewControllable: ViewControllable {
    var router: PauseConfirmationRouting? { get set }
}

final class PauseConfirmationRouter: Router<PauseConfirmationViewControllable>, PauseConfirmationRouting {

    // MARK: - Initialisation

    init(listener: PauseConfirmationListener,
         viewController: PauseConfirmationViewControllable) {
        self.listener = listener

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - Private

    private weak var listener: PauseConfirmationListener?
}

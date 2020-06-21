/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol InfectedViewControllable: ViewControllable, ThankYouListener {
    var router: InfectedRouting? { get set }

    func push(viewController: ViewControllable)
}

final class InfectedRouter: Router<InfectedViewControllable>, InfectedRouting {

    // MARK: - Initialisation

    init(listener: InfectedListener,
         viewController: InfectedViewControllable,
         thankYouBuilder: ThankYouBuildable) {
        self.listener = listener
        self.thankYouBuilder = thankYouBuilder
        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - InfectedRouting

    func infectedWantsDismissal(shouldDismissViewController: Bool) {
        listener?.infectedWantsDismissal(shouldDismissViewController: shouldDismissViewController)
    }

    func didUploadCodes() {
        guard thankYouViewController == nil else {
            return
        }

        let thankYouViewController = thankYouBuilder.build(withListener: viewController)
        self.thankYouViewController = thankYouViewController

        viewController.push(viewController: thankYouViewController)
    }

    // MARK: - Private

    private weak var listener: InfectedListener?

    private let thankYouBuilder: ThankYouBuildable
    private var thankYouViewController: ViewControllable?
}

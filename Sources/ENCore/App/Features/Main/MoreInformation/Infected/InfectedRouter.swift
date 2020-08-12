/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol InfectedViewControllable: ViewControllable, ThankYouListener, AboutListener {
    var router: InfectedRouting? { get set }

    func push(viewController: ViewControllable)
    func set(cardViewController: ViewControllable?)

    func present(viewController: ViewControllable)
    func dismiss(viewController: ViewControllable)
}

final class InfectedRouter: Router<InfectedViewControllable>, InfectedRouting {

    // MARK: - Initialisation

    init(listener: InfectedListener,
         viewController: InfectedViewControllable,
         thankYouBuilder: ThankYouBuildable,
         cardBuilder: CardBuildable,
         aboutBuilder: AboutBuildable) {
        self.listener = listener
        self.thankYouBuilder = thankYouBuilder
        self.cardBuilder = cardBuilder
        self.aboutBuilder = aboutBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - InfectedRouting

    func infectedWantsDismissal(shouldDismissViewController: Bool) {
        listener?.infectedWantsDismissal(shouldDismissViewController: shouldDismissViewController)
    }

    func didUploadCodes(withKey key: ExposureConfirmationKey) {
        guard thankYouViewController == nil else {
            return
        }

        let thankYouViewController = thankYouBuilder.build(withListener: viewController,
                                                           exposureConfirmationKey: key)
        self.thankYouViewController = thankYouViewController

        viewController.push(viewController: thankYouViewController)
    }

    func showInactiveCard() {
        let cardRouter = cardBuilder.build(type: .exposureOff)
        self.cardRouter = cardRouter

        viewController.set(cardViewController: cardRouter.viewControllable)
    }

    func removeInactiveCard() {
        guard cardRouter != nil else {
            return
        }

        viewController.set(cardViewController: nil)
        cardRouter = nil
    }

    func showFAQ() {
        guard aboutRouter == nil else {
            return
        }

        let router = aboutBuilder.build(withListener: viewController)
        viewController.present(viewController: router.viewControllable)

        aboutRouter = router
    }

    func hideFAQ(shouldDismissViewController: Bool) {
        guard let router = aboutRouter else {
            return
        }

        aboutRouter = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: router.viewControllable)
        }
    }

    // MARK: - Private

    private weak var listener: InfectedListener?

    private let thankYouBuilder: ThankYouBuildable
    private var thankYouViewController: ViewControllable?

    private let cardBuilder: CardBuildable
    private var cardRouter: (Routing & CardTypeSettable)?

    private let aboutBuilder: AboutBuildable
    private var aboutRouter: Routing?
}

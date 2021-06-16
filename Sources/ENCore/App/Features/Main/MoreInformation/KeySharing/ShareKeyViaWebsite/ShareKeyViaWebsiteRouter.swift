/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable(history:present=true;push=true;set=true;presentInNavigationController=true;dismiss=true)
protocol ShareKeyViaWebsiteViewControllable: ViewControllable, ThankYouListener, HelpDetailListener {
    var router: ShareKeyViaWebsiteRouting? { get set }

    func push(viewController: ViewControllable)
    func set(cardViewController: ViewControllable?)

    func presentInNavigationController(viewController: ViewControllable)
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> ())?)
    func dismiss(viewController: ViewControllable)
}

final class ShareKeyViaWebsiteRouter: Router<ShareKeyViaWebsiteViewControllable>, ShareKeyViaWebsiteRouting {

    // MARK: - Initialisation

    init(listener: ShareKeyViaWebsiteListener,
         viewController: ShareKeyViaWebsiteViewControllable,
         thankYouBuilder: ThankYouBuildable,
         cardBuilder: CardBuildable,
         helpDetailBuilder: HelpDetailBuildable,
         alertControllerBuilder: AlertControllerBuildable) {
        self.listener = listener
        self.thankYouBuilder = thankYouBuilder
        self.cardBuilder = cardBuilder
        self.helpDetailBuilder = helpDetailBuilder
        self.alertControllerBuilder = alertControllerBuilder
        
        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - ShareKeyViaWebsiteRouting

    func shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: Bool) {
        listener?.shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: shouldDismissViewController)
    }
    
    func didCompleteScreen(withKey key: ExposureConfirmationKey) {
        guard thankYouViewController == nil else {
            return
        }

        let alertController = alertControllerBuilder.buildAlertController(
            withTitle: .moreInformationKeySharingCoronaTestCompleteTitle,
            message: .moreInformationKeySharingCoronaTestCompleteContent,
            preferredStyle: .alert)
        
        alertController.addAction(alertControllerBuilder.buildAlertAction(title: .moreInformationKeySharingCoronaTestCompleteCancel, style: .cancel, handler: nil))
        alertController.addAction(alertControllerBuilder.buildAlertAction(title: .moreInformationKeySharingCoronaTestCompleteOK, style: .default) { [weak self] (_) in
            guard let self = self else { return }
            
            let thankYouViewController = self.thankYouBuilder.build(
                withListener: self.viewController,
                exposureConfirmationKey: key
            )
            self.thankYouViewController = thankYouViewController
            self.viewController.push(viewController: thankYouViewController)
        })
        
        viewController.present(alertController, animated: true, completion: nil)
    }

    func showInactiveCard() {
        let cardRouter = cardBuilder.build(listener: nil, types: [.exposureOff])
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
        guard helpDetailViewController == nil else {
            return
        }

        let question = HelpQuestion(question: .helpFaqUploadKeysTitle, answer: .helpFaqUploadKeysDescription)
        let controller = helpDetailBuilder.build(withListener: viewController, shouldShowEnableAppButton: false, entry: HelpOverviewEntry.question(question))
        viewController.presentInNavigationController(viewController: controller)

        helpDetailViewController = controller
    }

    func hideFAQ(shouldDismissViewController: Bool) {
        guard let controller = helpDetailViewController else {
            return
        }

        helpDetailViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: controller)
        }
    }

    // MARK: - Private

    private weak var listener: ShareKeyViaWebsiteListener?

    private let thankYouBuilder: ThankYouBuildable
    private var thankYouViewController: ViewControllable?

    private let cardBuilder: CardBuildable
    private var cardRouter: (Routing & CardTypeSettable)?

    private let helpDetailBuilder: HelpDetailBuildable
    private var helpDetailViewController: ViewControllable?
    
    private let alertControllerBuilder: AlertControllerBuildable
}

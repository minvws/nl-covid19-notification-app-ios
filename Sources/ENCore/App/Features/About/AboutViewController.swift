/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit
import WebKit

/// @mockable
protocol AboutRouting: Routing {
    func routeToOverview()
    func routeToHelpQuestion(question: HelpQuestion)
    func dismissHelpQuestion(shouldDismissViewController: Bool)
    func detachAboutOverview(shouldDismissViewController: Bool)
    func routeToAppInformation()
}

final class AboutViewController: NavigationController, AboutViewControllable, UIAdaptivePresentationControllerDelegate {
    weak var router: AboutRouting?

    init(listener: AboutListener, theme: Theme) {
        self.listener = listener
        super.init(theme: theme)
        modalPresentationStyle = .popover
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.aboutRequestsDismissal(shouldHideViewController: false)
    }

    // MARK: - AboutViewControllable

    func push(viewController: ViewControllable, animated: Bool) {
        pushViewController(viewController.uiviewController, animated: animated)
    }

    func dismiss(viewController: ViewControllable, animated: Bool) {
        viewController.uiviewController.dismiss(animated: animated)
    }

    // MARK: - AboutOverviewListener

    func aboutOverviewRequestsDismissal(shouldDismissViewController: Bool) {
        router?.detachAboutOverview(shouldDismissViewController: shouldDismissViewController)
        listener?.aboutRequestsDismissal(shouldHideViewController: shouldDismissViewController)
    }

    func aboutOverviewRequestsRouteTo(question: HelpQuestion) {
        router?.routeToHelpQuestion(question: question)
    }

    func aboutOverviewRequestsRouteToAppInformation() {
        router?.routeToAppInformation()
    }

    // MARK: - HelpDetailListener

    func helpDetailDidTapEnableAppButton() {}

    func helpDetailRequestsDismissal(shouldDismissViewController: Bool) {
        router?.dismissHelpQuestion(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - ViewController Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        router?.routeToOverview()
    }

    // MARK: - Private

    private weak var listener: AboutListener?
}

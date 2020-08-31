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
    func routeToAboutEntry(entry: AboutEntry)
    func routeToAppInformation()
    func routeToTechnicalInformation()
    func detachHelpQuestion()
    func detachAboutOverview()
    func detachReceivedNotification()
}

final class AboutViewController: NavigationController, AboutViewControllable, UIAdaptivePresentationControllerDelegate {

    weak var router: AboutRouting?

    init(listener: AboutListener, theme: Theme) {
        self.listener = listener
        super.init(theme: theme)
        modalPresentationStyle = .popover
        navigationItem.rightBarButtonItem = closeBarButtonItem
        presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.aboutRequestsDismissal(shouldHideViewController: false)
    }

    @objc func didTapClose() {
        listener?.aboutRequestsDismissal(shouldHideViewController: true)
    }

    // MARK: - AboutViewControllable

    func push(viewController: ViewControllable, animated: Bool) {
        pushViewController(viewController.uiviewController, animated: animated)
    }

    func cleanNavigationStackIfNeeded() {
        if let first = viewControllers.first, let last = viewControllers.last {
            viewControllers = [first, last]
        }
    }

    // MARK: - AboutOverviewListener

    func aboutOverviewRequestsRouteTo(entry: AboutEntry) {
        router?.routeToAboutEntry(entry: entry)
    }

    func aboutOverviewRequestsRouteToAppInformation() {
        router?.routeToAppInformation()
    }

    func aboutOverviewRequestsRouteToTechnicalInformation() {
        router?.routeToTechnicalInformation()
    }

    // MARK: - HelpDetailListener

    func helpDetailDidTapEnableAppButton() {}

    func helpDetailRequestsDismissal(shouldDismissViewController: Bool) {
        router?.detachHelpQuestion()
        listener?.aboutRequestsDismissal(shouldHideViewController: shouldDismissViewController)
    }

    func helpDetailRequestRedirect(to content: LinkedContent) {
        if let entry = content as? AboutEntry {
            router?.routeToAboutEntry(entry: entry)
        }
    }

    // MARK: - WebviewListener

    func webviewRequestsDismissal(shouldHideViewController: Bool) {
        listener?.aboutRequestsDismissal(shouldHideViewController: shouldHideViewController)
    }

    // MARK: - ReceivedNotificationListener

    func receivedNotificationWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachReceivedNotification()
        listener?.aboutRequestsDismissal(shouldHideViewController: shouldDismissViewController)
    }

    // MARK: - ViewController Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        router?.routeToOverview()
    }

    // MARK: - Private

    private weak var listener: AboutListener?
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))
}

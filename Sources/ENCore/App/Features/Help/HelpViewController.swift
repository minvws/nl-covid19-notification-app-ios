/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit
import WebKit

/// @mockable
protocol HelpRouting: Routing {
    func routeToOverview(shouldShowEnableAppButton: Bool)
    func routeTo(question: HelpQuestion, shouldShowEnableAppButton: Bool)
    func detachHelpOverview(shouldDismissViewController: Bool)
    func detachHelpDetail(shouldDismissViewController: Bool)
}

final class HelpViewController: NavigationController, HelpViewControllable, UIAdaptivePresentationControllerDelegate {

    weak var router: HelpRouting?

    init(listener: HelpListener, shouldShowEnableAppButton: Bool, exposureController: ExposureControlling, theme: Theme) {
        self.listener = listener
        self.shouldShowEnableAppButton = shouldShowEnableAppButton
        self.exposureController = exposureController
        super.init(theme: theme)
        modalPresentationStyle = .popover

        navigationItem.rightBarButtonItem = closeBarButtonItem
    }

    // MARK: - HelpViewControllable

    func push(viewController: ViewControllable, animated: Bool) {
        pushViewController(viewController.uiviewController, animated: animated)
    }

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController, animated: animated, completion: completion)
    }

    func dismiss(viewController: ViewControllable, animated: Bool) {
        viewController.uiviewController.dismiss(animated: animated)
    }

    // MARK: - HelpOverviewListener

    func helpOverviewRequestsRouteTo(question: HelpQuestion) {
        router?.routeTo(question: question, shouldShowEnableAppButton: shouldShowEnableAppButton)
    }

    func helpOverviewRequestsDismissal(shouldDismissViewController: Bool) {
        router?.detachHelpOverview(shouldDismissViewController: true)
    }

    func helpOverviewDidTapEnableAppButton() {
        router?.detachHelpOverview(shouldDismissViewController: true)
        self.listener?.helpRequestsEnableApp()
    }

    // MARK: - HelpDetailListener

    func helpDetailRequestsDismissal(shouldDismissViewController: Bool) {
        router?.detachHelpDetail(shouldDismissViewController: true)
    }

    func helpDetailDidTapEnableAppButton() {

        router?.detachHelpDetail(shouldDismissViewController: true)
        self.listener?.helpRequestsEnableApp()
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        router?.detachHelpDetail(shouldDismissViewController: false)
        listener?.helpRequestsDismissal(shouldHideViewController: false)
    }

    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        router?.routeToOverview(shouldShowEnableAppButton: shouldShowEnableAppButton)
    }

    @objc func didTapClose() {
        router?.detachHelpOverview(shouldDismissViewController: true)
        listener?.helpRequestsDismissal(shouldHideViewController: true)
    }

    // MARK: - Private

    private weak var listener: HelpListener?
    private let shouldShowEnableAppButton: Bool
    private let exposureController: ExposureControlling
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))
}

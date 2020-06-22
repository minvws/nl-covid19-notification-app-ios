/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import WebKit

/// @mockable
protocol HelpRouting: Routing {
    func routeToOverview(shouldShowEnableAppButton: Bool)
    func routeTo(question: HelpQuestion, shouldShowEnableAppButton: Bool)
}

final class HelpViewController: NavigationController, HelpViewControllable {

    weak var router: HelpRouting?

    init(listener: HelpListener, shouldShowEnableAppButton: Bool, exposureController: ExposureControlling, theme: Theme) {
        self.listener = listener
        self.shouldShowEnableAppButton = shouldShowEnableAppButton
        self.exposureController = exposureController
        super.init(theme: theme)
        modalPresentationStyle = .popover
    }

    // MARK: - HelpViewControllable

    func push(viewController: ViewControllable, animated: Bool) {
        pushViewController(viewController.uiviewController, animated: animated)
    }

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController, animated: animated, completion: completion)
    }

    // MARK: - HelpOverviewListener

    func helpOverviewRequestsRouteTo(question: HelpQuestion) {
        router?.routeTo(question: question, shouldShowEnableAppButton: shouldShowEnableAppButton)
    }

    func helpOverviewRequestsDismissal(shouldDismissViewController: Bool) {
        self.dismiss(animated: true)
    }

    func helpOverviewDidTapEnableAppButton() {
        self.dismiss(animated: true) {
            self.listener?.helpRequestsEnableApp()
        }
    }

    // MARK: - HelpDetailListener

    func helpDetailRequestsDismissal(shouldDismissViewController: Bool) {
        self.dismiss(animated: true)
    }

    func helpDetailDidTapEnableAppButton() {
        self.dismiss(animated: true) {
            self.listener?.helpRequestsEnableApp()
        }
    }

    // MARK: - ViewController Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        router?.routeToOverview(shouldShowEnableAppButton: shouldShowEnableAppButton)
    }

    // MARK: - Private

    private weak var listener: HelpListener?
    private let shouldShowEnableAppButton: Bool
    private let exposureController: ExposureControlling
}

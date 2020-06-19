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
    func routeToOverview()
    func routeTo(question: HelpQuestion)
}

final class HelpViewController: NavigationController, HelpViewControllable {

    weak var router: HelpRouting?

    init(listener: HelpListener, theme: Theme) {
        self.listener = listener
        super.init(theme: theme)
        modalPresentationStyle = .fullScreen
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
        // TODO:
    }

    func helpOverviewRequestsDismissal(shouldDismissViewController: Bool) {
        // TODO:
    }

    func helpOverviewDidTapEnableAppButton() {
        // TODO:
    }

    // MARK: - HelpDetailListener

    func helpDetailRequestsDismissal(shouldDismissViewController: Bool) {
        // TODO:
    }

    // MARK: - ViewController Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        router?.routeToOverview()
    }

    // MARK: - Private

    private weak var listener: HelpListener?
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol HelpViewControllable: ViewControllable, HelpOverviewListener, HelpDetailListener {
    var router: HelpRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class HelpRouter: Router<HelpViewControllable>, HelpRouting {

    init(viewController: HelpViewControllable,
         helpOverviewBuilder: HelpOverviewBuildable,
         helpDetailBuilder: HelpDetailBuildable) {

        self.helpOverviewBuilder = helpOverviewBuilder
        self.helpDetailBuilder = helpDetailBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }

    func routeToOverview(shouldShowEnableAppButton: Bool) {
        guard helpOverviewViewController == nil else {
            return
        }

        let helpOverviewViewController = helpOverviewBuilder.build(withListener: viewController,
                                                                   shouldShowEnableAppButton: shouldShowEnableAppButton)

        self.helpOverviewViewController = helpOverviewViewController

        viewController.push(viewController: helpOverviewViewController, animated: false)
    }

    func routeTo(question: HelpQuestion, shouldShowEnableAppButton: Bool) {
        let helpDetailViewController = helpDetailBuilder.build(withListener: viewController,
                                                               shouldShowEnableAppButton: shouldShowEnableAppButton,
                                                               question: question)
        self.helpDetailViewController = helpDetailViewController

        viewController.push(viewController: helpDetailViewController, animated: true)
    }

    func detachHelpOverview(shouldDismissViewController: Bool) {
        guard let helpOverviewViewController = helpOverviewViewController else { return }
        self.helpOverviewViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: helpOverviewViewController, animated: true)
        }
    }

    func detachHelpDetail(shouldDismissViewController: Bool) {
        guard let helpDetailViewController = helpDetailViewController else { return }
        self.helpDetailViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: helpDetailViewController, animated: true)
        }
    }

    private let helpOverviewBuilder: HelpOverviewBuildable
    private var helpOverviewViewController: ViewControllable?

    private let helpDetailBuilder: HelpDetailBuildable
    private var helpDetailViewController: ViewControllable?
}

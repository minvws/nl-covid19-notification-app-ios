/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

/// @mockable
protocol AboutViewControllable: ViewControllable, AboutOverviewListener, HelpDetailListener, AppInformationListener, TechnicalInformationListener {
    var router: AboutRouting? { get set }
    func push(viewController: ViewControllable, animated: Bool)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class AboutRouter: Router<AboutViewControllable>, AboutRouting {

    init(viewController: AboutViewControllable,
         aboutOverviewBuilder: AboutOverviewBuildable,
         helpDetailBuilder: HelpDetailBuildable,
         appInformationBuilder: AppInformationBuildable,
         technicalInformationBuilder: TechnicalInformationBuildable) {
        self.helpDetailBuilder = helpDetailBuilder
        self.aboutOverviewBuilder = aboutOverviewBuilder
        self.appInformationBuilder = appInformationBuilder
        self.technicalInformationBuilder = technicalInformationBuilder
        super.init(viewController: viewController)
        viewController.router = self
    }

    func routeToOverview() {
        guard aboutOverviewViewController == nil else {
            return
        }

        let aboutOverviewViewController = aboutOverviewBuilder.build(withListener: viewController)
        self.aboutOverviewViewController = aboutOverviewViewController

        viewController.push(viewController: aboutOverviewViewController, animated: false)
    }

    func detachAboutOverview(shouldDismissViewController: Bool) {
        guard let aboutOverviewViewController = aboutOverviewViewController else { return }
        self.aboutOverviewViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: aboutOverviewViewController, animated: true)
        }
    }

    func routeToHelpQuestion(question: HelpQuestion) {
        let helpDetailViewController = helpDetailBuilder.build(withListener: viewController,
                                                               shouldShowEnableAppButton: false,
                                                               question: question)
        self.helpDetailViewController = helpDetailViewController

        viewController.push(viewController: helpDetailViewController, animated: true)
    }

    func dismissHelpQuestion(shouldDismissViewController: Bool) {
        guard let helpDetailViewController = helpDetailViewController else { return }
        self.helpDetailViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: helpDetailViewController, animated: true)
        }
    }

    func routeToAppInformation() {
        let appInformationViewController = appInformationBuilder.build(withListener: viewController)
        self.appInformationViewController = aboutOverviewViewController

        viewController.push(viewController: appInformationViewController, animated: true)
    }

    func routeToTechninalInformation() {
        let technicalInformationRouter = technicalInformationBuilder.build(withListener: viewController)
        self.technicalInformationRouter = technicalInformationRouter

        viewController.push(viewController: technicalInformationRouter.viewControllable, animated: true)
    }

    // MARK: - Private

    private let helpDetailBuilder: HelpDetailBuildable
    private var helpDetailViewController: ViewControllable?

    private let aboutOverviewBuilder: AboutOverviewBuildable
    private var aboutOverviewViewController: ViewControllable?

    private let appInformationBuilder: AppInformationBuildable
    private var appInformationViewController: ViewControllable?

    private let technicalInformationBuilder: TechnicalInformationBuildable
    private var technicalInformationRouter: Routing?
}

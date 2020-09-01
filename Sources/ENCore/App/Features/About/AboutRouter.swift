/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import StoreKit
import UIKit

/// @mockable
protocol AboutViewControllable: ViewControllable, AboutOverviewListener, HelpDetailListener, AppInformationListener, TechnicalInformationListener, WebviewListener, ReceivedNotificationListener {
    var router: AboutRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func cleanNavigationStackIfNeeded()
}

final class AboutRouter: Router<AboutViewControllable>, AboutRouting, Logging {

    init(viewController: AboutViewControllable,
         aboutOverviewBuilder: AboutOverviewBuildable,
         helpDetailBuilder: HelpDetailBuildable,
         appInformationBuilder: AppInformationBuildable,
         technicalInformationBuilder: TechnicalInformationBuildable,
         webviewBuilder: WebviewBuildable,
         receivedNotificationBuilder: ReceivedNotificationBuildable) {
        self.helpDetailBuilder = helpDetailBuilder
        self.aboutOverviewBuilder = aboutOverviewBuilder
        self.appInformationBuilder = appInformationBuilder
        self.technicalInformationBuilder = technicalInformationBuilder
        self.webviewBuilder = webviewBuilder
        self.receivedNotificationBuildable = receivedNotificationBuilder
        super.init(viewController: viewController)
        viewController.router = self
    }

    func routeToOverview() {
        guard aboutOverviewViewController == nil else { return }

        let aboutOverviewViewController = aboutOverviewBuilder.build(withListener: viewController)
        self.aboutOverviewViewController = aboutOverviewViewController

        viewController.push(viewController: aboutOverviewViewController, animated: false)
    }

    func detachAboutOverview() {
        self.aboutOverviewViewController = nil
    }

    func routeToAboutEntry(entry: AboutEntry) {
        switch entry {
        case .question:
            routeToHelpQuestion(entry: entry)
        case .rate:
            routeToRateApp()
        case let .link(_, urlString):
            routeToWebView(urlString: urlString)
        case let .notificationExplanation(_, linkedContent):
            routeToNotificationExplanation(linkedContent: linkedContent)
        case .appInformation:
            routeToAppInformation()
        case .technicalInformation:
            routeToTechnicalInformation()
        }

        viewController.cleanNavigationStackIfNeeded()
    }

    func detachHelpQuestion() {
        self.helpDetailViewController = nil
    }

    func routeToAppInformation() {
        let appInformationViewController = appInformationBuilder.build(withListener: viewController)
        self.appInformationViewController = aboutOverviewViewController

        viewController.push(viewController: appInformationViewController, animated: true)
        viewController.cleanNavigationStackIfNeeded()
    }

    func routeToTechnicalInformation() {
        let technicalInformationRouter = technicalInformationBuilder.build(withListener: viewController)
        self.technicalInformationRouter = technicalInformationRouter

        viewController.push(viewController: technicalInformationRouter.viewControllable, animated: true)
        viewController.cleanNavigationStackIfNeeded()
    }

    func detachReceivedNotification() {
        self.receivedNotificationViewController = nil
    }

    // MARK: - Private

    private func routeToNotificationExplanation(linkedContent: [LinkedContent]) {
        let receivedNotificationViewController = receivedNotificationBuildable.build(withListener: viewController,
                                                                                     linkedContent: linkedContent,
                                                                                     actionButtonTitle: nil)
        self.receivedNotificationViewController = receivedNotificationViewController

        viewController.push(viewController: receivedNotificationViewController, animated: true)

        viewController.cleanNavigationStackIfNeeded()
    }

    private func routeToHelpQuestion(entry: HelpDetailEntry) {
        let helpDetailViewController = helpDetailBuilder.build(withListener: viewController,
                                                               shouldShowEnableAppButton: false,
                                                               entry: entry)
        self.helpDetailViewController = helpDetailViewController

        viewController.push(viewController: helpDetailViewController, animated: true)
    }

    private func routeToRateApp() {
        SKStoreReviewController.requestReview()
    }

    private func routeToWebView(urlString: String) {
        guard let url = URL(string: urlString) else {
            return logError("Cannot create URL from: \(urlString)")
        }

        let webviewViewController = webviewBuilder.build(withListener: viewController, url: url)
        self.webviewViewController = webviewViewController
        viewController.push(viewController: webviewViewController, animated: true)
    }

    private let webviewBuilder: WebviewBuildable
    private var webviewViewController: ViewControllable?

    private let helpDetailBuilder: HelpDetailBuildable
    private var helpDetailViewController: ViewControllable?

    private let aboutOverviewBuilder: AboutOverviewBuildable
    private var aboutOverviewViewController: ViewControllable?

    private let appInformationBuilder: AppInformationBuildable
    private var appInformationViewController: ViewControllable?

    private let technicalInformationBuilder: TechnicalInformationBuildable
    private var technicalInformationRouter: Routing?

    private let receivedNotificationBuildable: ReceivedNotificationBuildable
    private var receivedNotificationViewController: ViewControllable?
}

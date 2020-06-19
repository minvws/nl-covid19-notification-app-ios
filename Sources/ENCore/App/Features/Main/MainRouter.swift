/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

/// @mockable
protocol MainViewControllable: ViewControllable, StatusListener, MoreInformationListener, AboutListener, ReceivedNotificationListener, RequestTestListener, InfectedListener {
    var router: MainRouting? { get set }

    func embed(stackedViewController: ViewControllable)
    func present(viewController: ViewControllable, animated: Bool)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class MainRouter: Router<MainViewControllable>, MainRouting {

    init(viewController: MainViewControllable,
         statusBuilder: StatusBuildable,
         moreInformationBuilder: MoreInformationBuildable,
         aboutBuilder: AboutBuildable,
         receivedNotificationBuilder: ReceivedNotificationBuildable,
         requestTestBuilder: RequestTestBuildable,
         infectedBuilder: InfectedBuildable) {
        self.statusBuilder = statusBuilder
        self.moreInformationBuilder = moreInformationBuilder
        self.aboutBuilder = aboutBuilder
        self.receivedNotificationBuilder = receivedNotificationBuilder
        self.requestTestBuilder = requestTestBuilder
        self.infectedBuilder = infectedBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - MainRouting

    func attachStatus(topAnchor: NSLayoutYAxisAnchor) {
        guard statusRouter == nil else { return }

        let statusRouter = statusBuilder.build(withListener: viewController, topAnchor: topAnchor)
        self.statusRouter = statusRouter

        viewController.embed(stackedViewController: statusRouter.viewControllable)
    }

    func attachMoreInformation() {
        guard moreInformationViewController == nil else { return }

        let moreInformationViewController = moreInformationBuilder.build(withListener: viewController)
        self.moreInformationViewController = moreInformationViewController

        viewController.embed(stackedViewController: moreInformationViewController)
    }

    func routeToAboutApp() {
        guard aboutViewController == nil else { return }

        let aboutViewController = aboutBuilder.build(withListener: viewController)
        self.aboutViewController = aboutViewController

        viewController.present(viewController: aboutViewController, animated: true)
    }

    func detachAboutApp(shouldHideViewController: Bool) {
        guard let aboutViewController = aboutViewController else { return }
        self.aboutViewController = nil

        if shouldHideViewController {
            viewController.dismiss(viewController: aboutViewController, animated: true)
        }
    }

    func routeToReceivedNotification() {
        guard receivedNotificationViewController == nil else {
            return
        }

        let receivedNotificationViewController = receivedNotificationBuilder.build(withListener: viewController)
        self.receivedNotificationViewController = receivedNotificationViewController

        viewController.present(viewController: receivedNotificationViewController, animated: true)
    }

    func detachReceivedNotification(shouldDismissViewController: Bool) {
        guard let receivedNotificationViewController = receivedNotificationViewController else {
            return
        }
        self.receivedNotificationViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: receivedNotificationViewController, animated: true)
        }
    }

    func routeToInfected() {
        guard infectedRouter == nil else {
            return
        }

        let infectedRouter = infectedBuilder.build(withListener: viewController)
        self.infectedRouter = infectedRouter

        viewController.present(viewController: infectedRouter.viewControllable, animated: true)
    }

    func detachInfected(shouldDismissViewController: Bool) {
        guard let infectedRouter = infectedRouter else {
            return
        }
        self.infectedRouter = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: infectedRouter.viewControllable, animated: true)
        }
    }

    func routeToRequestTest() {
        guard requestTestViewController == nil else {
            return
        }

        let requestTestViewController = requestTestBuilder.build(withListener: viewController)
        self.requestTestViewController = requestTestViewController

        viewController.present(viewController: requestTestViewController, animated: true)
    }

    func detachRequestTest(shouldDismissViewController: Bool) {
        guard let requestTestViewController = requestTestViewController else {
            return
        }
        self.requestTestViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: requestTestViewController, animated: true)
        }
    }

    // MARK: - Private

    private let statusBuilder: StatusBuildable
    private var statusRouter: Routing?

    private let moreInformationBuilder: MoreInformationBuildable
    private var moreInformationViewController: ViewControllable?

    private let aboutBuilder: AboutBuildable
    private var aboutViewController: ViewControllable?

    private let receivedNotificationBuilder: ReceivedNotificationBuildable
    private var receivedNotificationViewController: ViewControllable?

    private let requestTestBuilder: RequestTestBuildable
    private var requestTestViewController: ViewControllable?

    private let infectedBuilder: InfectedBuildable
    private var infectedRouter: Routing?
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// @mockable
protocol DashboardViewControllable: ViewControllable, DashboardOverviewListener, DashboardDetailListener {
    var router: DashboardRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func replaceSameOrPush(viewController: ViewControllable, animated: Bool)
}

final class DashboardRouter: Router<DashboardViewControllable>, DashboardRouting, Logging {

    // MARK: - Initialisation

    init(viewController: DashboardViewControllable,
         overviewBuilder: DashboardOverviewBuildable,
         detailBuilder: DashboardDetailBuildable) {
        self.overviewBuilder = overviewBuilder
        self.detailBuilder = detailBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }

    func routeToOverview(with data: DashboardData) {
        guard overviewViewController == nil else { return }

        let overviewViewController = overviewBuilder.build(withData: data, listener: viewController)
        self.overviewViewController = overviewViewController

        viewController.push(viewController: overviewViewController, animated: false)
    }

    func routeToDetail(with identifier: DashboardIdentifier, data: DashboardData, animated: Bool) {
        let detailViewController = detailBuilder.build(withData: data, listener: viewController, identifier: identifier)

        viewController.replaceSameOrPush(viewController: detailViewController, animated: animated)
    }

    func routeToExternalURL(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            logError("Unable to open \(url)")
        }
    }

    // MARK: - Private

    private let overviewBuilder: DashboardOverviewBuildable
    private let detailBuilder: DashboardDetailBuildable
    private var overviewViewController: ViewControllable?
}

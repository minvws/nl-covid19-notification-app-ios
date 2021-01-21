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
protocol SettingsViewControllable: ViewControllable, SettingsOverviewListener, MobileDataListener {
    var router: SettingsRouting? { get set }

    func push(viewController: ViewControllable, animated: Bool)
    func presentInNavigationController(viewController: ViewControllable, animated: Bool)
    func cleanNavigationStackIfNeeded()
}

final class SettingsRouter: Router<SettingsViewControllable>, SettingsRouting, Logging {

    init(viewController: SettingsViewControllable,
         settingsOverviewBuilder: SettingsOverviewBuildable,
         mobileDataBuilder: MobileDataBuildable,
         pauseConfirmationBuilder: PauseConfirmationBuildable,
         exposureDataController: ExposureDataControlling) {

        self.settingsOverviewBuilder = settingsOverviewBuilder
        self.mobileDataBuilder = mobileDataBuilder
        self.pauseConfirmationBuilder = pauseConfirmationBuilder
        self.exposureDataController = exposureDataController

        super.init(viewController: viewController)
        viewController.router = self
    }

    func routeToOverview() {
        guard settingsOverviewRouting == nil else { return }

        let settingsOverviewRouting = settingsOverviewBuilder.build(withListener: viewController)
        self.settingsOverviewRouting = settingsOverviewRouting

        viewController.push(viewController: settingsOverviewRouting.viewControllable, animated: false)
    }

    func routeToMobileData() {
        let mobileDataViewController = mobileDataBuilder.build(withListener: viewController)
        self.mobileDataViewController = mobileDataViewController

        viewController.push(viewController: mobileDataViewController, animated: true)
        viewController.cleanNavigationStackIfNeeded()
    }

    // MARK: - Private

    private let settingsOverviewBuilder: SettingsOverviewBuildable
    private var settingsOverviewRouting: Routing?

    private let mobileDataBuilder: MobileDataBuildable
    private var mobileDataViewController: ViewControllable?

    private let pauseConfirmationBuilder: PauseConfirmationBuildable
    private var pauseConfirmationViewController: ViewControllable?

    private let exposureDataController: ExposureDataControlling
}

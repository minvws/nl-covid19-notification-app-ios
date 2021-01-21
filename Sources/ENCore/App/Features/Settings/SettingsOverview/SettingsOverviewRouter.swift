/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// @mockable
protocol SettingsOverviewViewControllable: ViewControllable, PauseConfirmationListener {
    var router: SettingsOverviewRouting? { get set }

    /// Presents a viewController
    ///
    /// - Parameter viewController: ViewController to present
    /// - Parameter animated: Animates the transition
    /// - Parameter completion: Executed upon presentation completion
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
}

final class SettingsOverviewRouter: Router<SettingsOverviewViewControllable>, SettingsOverviewRouting {

    // MARK: - Initialisation

    init(listener: SettingsOverviewListener,
         viewController: SettingsOverviewViewControllable,
         exposureDataController: ExposureDataControlling,
         pauseConfirmationBuilder: PauseConfirmationBuildable) {
        self.listener = listener
        self.exposureDataController = exposureDataController
        self.pauseConfirmationBuilder = pauseConfirmationBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }

    func routeToPauseConfirmation(completion: @escaping () -> ()) {
        guard !exposureDataController.hidePauseInformation else {
            return
        }

        let router = pauseConfirmationBuilder.build(withListener: viewController)
        pauseConfirmationRouter = router

        viewController.present(viewController: router.viewControllable, animated: true, completion: nil)
    }

    // MARK: - Private

    private weak var listener: SettingsOverviewListener?
    private let exposureDataController: ExposureDataControlling
    private let pauseConfirmationBuilder: PauseConfirmationBuildable
    private var pauseConfirmationRouter: Routing?
}

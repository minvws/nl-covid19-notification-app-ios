/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit
import ENFoundation

/// @mockable
protocol CardViewControllable: ViewControllable, EnableSettingListener, WebviewListener {
    var router: CardRouting? { get set }

    func update(cardTypes: [CardType])
    func present(viewController: ViewControllable)
    func present(viewController: ViewControllable, animated: Bool, inNavigationController: Bool)
    func dismiss(viewController: ViewControllable)
}

final class CardRouter: Router<CardViewControllable>, CardRouting, CardTypeSettable, Logging {
    init(viewController: CardViewControllable,
         enableSettingBuilder: EnableSettingBuildable,
         webviewBuilder: WebviewBuildable,
         exposureController: ExposureControlling) {
        self.enableSettingBuilder = enableSettingBuilder
        self.webviewBuilder = webviewBuilder
        self.exposureController = exposureController

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - CardRouting

    func route(to enableSetting: EnableSetting) {
        let viewController = enableSettingBuilder.build(withListener: self.viewController,
                                                        setting: enableSetting)

        enableSettingViewController = viewController
        self.viewController.present(viewController: viewController)
    }

    func route(to url: URL) {
        guard webviewViewController == nil else { return }

        let webviewViewController = webviewBuilder.build(withListener: viewController, url: url)
        self.webviewViewController = webviewViewController

        viewController.present(viewController: webviewViewController, animated: true, inNavigationController: true)
    }
    
    func routeToRequestExposureNotificationPermission() {
        exposureController.requestExposureNotificationPermission { error in
            if let error = error {
                self.logError("Error `requestExposureNotificationPermission`: \(error.localizedDescription)")
            }
        }
    }

    func detachEnableSetting(hideViewController: Bool) {
        guard let viewController = enableSettingViewController else {
            return
        }

        enableSettingViewController = nil

        if hideViewController {
            self.viewController.dismiss(viewController: viewController)
        }
    }

    func detachWebview(shouldDismissViewController: Bool) {
        guard let webviewViewController = webviewViewController else {
            return
        }
        self.webviewViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: webviewViewController)
        }
    }

    // MARK: - CardTypeSettable

    var types: [CardType] = [.bluetoothOff] {
        didSet {
            viewController.update(cardTypes: types)
        }
    }

    // MARK: - Private

    private let enableSettingBuilder: EnableSettingBuildable
    private var enableSettingViewController: ViewControllable?

    private let webviewBuilder: WebviewBuildable
    private var webviewViewController: ViewControllable?
    private let exposureController: ExposureControlling
}

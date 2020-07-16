/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol CardViewControllable: ViewControllable, EnableSettingListener {
    var router: CardRouting? { get set }

    func update(cardType: CardType)
    func present(viewController: ViewControllable)
    func dismiss(viewController: ViewControllable)
}

final class CardRouter: Router<CardViewControllable>, CardRouting, CardTypeSettable {

    init(viewController: CardViewControllable,
         enableSettingBuilder: EnableSettingBuildable) {
        self.enableSettingBuilder = enableSettingBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - CardRouting

    func route(to enableSetting: EnableSetting) {
        let viewController = enableSettingBuilder.build(withListener: self.viewController,
                                                        setting: enableSetting)

        self.enableSettingViewController = viewController
        self.viewController.present(viewController: viewController)
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

    // MARK: - CardTypeSettable

    var type: CardType = .bluetoothOff {
        didSet {
            viewController.update(cardType: type)
        }
    }

    // MARK: - Private

    private let enableSettingBuilder: EnableSettingBuildable
    private var enableSettingViewController: ViewControllable?
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

struct EnableSettingAction {
    typealias Completion = () -> ()
    let action: (@escaping Completion) -> ()

    static var openSettings: EnableSettingAction {
        return .init { completion in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: { _ in completion() })
        }
    }

    static func custom(action: @escaping (Completion) -> ()) -> EnableSettingAction {
        return EnableSettingAction(action: action)
    }
}

enum EnableSetting {
    case enableExposureNotifications
    case enableBluetooth
    case enableLocalNotifications

    func model(theme: Theme) -> EnableSettingModel {
        switch self {
        case .enableExposureNotifications:
            return EnableSettingModel.enableExposureNotifications(theme)
        case .enableBluetooth:
            return EnableSettingModel.enableBluetooth(theme)
        case .enableLocalNotifications:
            return EnableSettingModel.enableLocalNotifications(theme)
        }
    }
}

struct EnableSettingModel {
    let title: String
    let steps: [EnableSettingStep]
    let action: EnableSettingAction?
    let actionTitle: String

    static var enableExposureNotifications: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black) }

            let step1 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotificationsStep1),
                                          action: nil)
            let step2 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotificationsStep2),
                                          action: .toggle(description: .enableSettingsExposureNotificationsStep2ActionTitle))

            return .init(title: .enableSettingsExposureNotificationsTitle,
                         steps: [step1, step2],
                         action: .openSettings,
                         actionTitle: .enableSettingsExposureNotificationsAction)
        }
    }

    static var enableBluetooth: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black) }

            let step1 = EnableSettingStep(description: fromHtml(.enableBluetoothSettingTitleRow1),
                                          action: .custom(image: Image.named("SettingsIcon"), description: .enableBluetoothSettingTitleSettingRow1, showChevron: false))
            let step2 = EnableSettingStep(description: fromHtml(.enableBluetoothSettingTitleRow2),
                                          action: .custom(image: Image.named("BluetoothIcon"), description: .enableBluetoothSettingTitleSettingRow2, showChevron: true))
            let step3 = EnableSettingStep(description: fromHtml(.enableBluetoothSettingTitleRow3),
                                          action: .toggle(description: .enableBluetoothSettingTitleSettingRow3))

            return .init(title: .enableSettingsBluetoothTitle,
                         steps: [step1, step2, step3],
                         action: nil,
                         actionTitle: .enableSettingsBluetoothAction)
        }
    }

    static var enableLocalNotifications: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black) }

            let step1 = EnableSettingStep(description: fromHtml(.enableSettingsLocalNotificationsStep1),
                                          action: nil)
            let step2 = EnableSettingStep(description: fromHtml(.enableSettingsLocalNotificationsStep2),
                                          action: .cell(description: .enableSettingsLocalNotificationsStep2ActionTitle))
            let step3 = EnableSettingStep(description: fromHtml(.enableSettingsLocalNotificationsStep3),
                                          action: .toggle(description: .enableSettingsLocalNotificationsStep3ActionTitle))

            return .init(title: .enableSettingsLocalNotificationsTitle,
                         steps: [step1, step2, step3],
                         action: .openSettings,
                         actionTitle: .enableSettingsLocalNotificationsAction)
        }
    }
}

struct EnableSettingStep {
    enum Action {
        case toggle(description: String)
        case cell(description: String)
        case custom(image: UIImage?, description: String, showChevron: Bool)
    }

    let description: NSAttributedString
    let action: Action?
}

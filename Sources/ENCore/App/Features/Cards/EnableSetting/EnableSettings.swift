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
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

            if #available(iOS 13.7, *), FeatureFlags.exposureNotificationExplanation.enabled {
                let step1 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotificationsStep1),
                                              action: nil)
                let step2 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotifications137Step2),
                                              action: .custom(image: Image.named("ExposureNotifications"), description: .enableSettingsExposureNotifications137Step2ActionTitle, showChevron: true))

                let step3 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotifications137Step3),
                                              action: .toggle(description: .enableSettingsExposureNotifications137Step3ActionTitle))

                let step4 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotifications137Step4),
                                              action: .linkCell(description: .enableSettingsExposureNotifications137Step4ActionTitle))

                return .init(title: .enableSettingsExposureNotificationsTitle,
                             steps: [step1, step2, step3, step4],
                             action: .openSettings,
                             actionTitle: .enableSettingsExposureNotificationsAction)

            } else {
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
    }

    static var enableBluetooth: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

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
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

            let step1 = EnableSettingStep(description: fromHtml(.enableSettingsLocalNotificationsStep1),
                                          action: nil)
            let step2 = EnableSettingStep(description: fromHtml(.enableSettingsLocalNotificationsStep2),
                                          action: .custom(image: Image.named("Notification"), description: .enableSettingsLocalNotificationsStep2ActionTitle, showChevron: true))
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
        case linkCell(description: String)
        case toggle(description: String)
        case custom(image: UIImage?, description: String, showChevron: Bool)
    }

    let description: NSAttributedString
    let action: Action?
}

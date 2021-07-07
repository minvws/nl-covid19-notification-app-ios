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
    case updateOperatingSystem
    case connectToInternet

    func model(theme: Theme, environmentController: EnvironmentControlling) -> EnableSettingModel {
        switch self {
        case .enableExposureNotifications:
            if environmentController.isiOS137orHigher {
                return EnableSettingModel.enableExposureNotificationsExtended(theme)
            } else {
                return EnableSettingModel.enableExposureNotifications(theme)
            }
        case .enableBluetooth:
            return EnableSettingModel.enableBluetooth(theme)
        case .enableLocalNotifications:
            return EnableSettingModel.enableLocalNotifications(theme)
        case .updateOperatingSystem:
            return EnableSettingModel.updateOperatingSystem(theme)
        case .connectToInternet:
            return EnableSettingModel.connectToInternet(theme)
        }
    }
}

struct EnableSettingModel {
    
    let title: String
    let introduction: NSAttributedString?
    let stepTitle: NSAttributedString?
    let footer: NSAttributedString?
    let steps: [EnableSettingStep]
    let action: EnableSettingAction?
    let actionTitle: String?

    private init(
        title: String,
        introduction: NSAttributedString? = nil,
        stepTitle: NSAttributedString? = nil,
        footer: NSAttributedString? = nil,
        steps: [EnableSettingStep],
        action: EnableSettingAction?,
        actionTitle: String?) {
        
        self.title = title
        self.introduction = introduction
        self.stepTitle = stepTitle
        self.footer = footer
        self.steps = steps
        self.action = action
        self.actionTitle = actionTitle
    }
    
    static var enableExposureNotifications: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

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

    static var enableExposureNotificationsExtended: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

            let step1 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotificationsStep1),
                                          action: nil)
            let step2 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotifications137Step2),
                                          action: .custom(image: .exposureNotifications, description: .enableSettingsExposureNotifications137Step2ActionTitle, showChevron: true, showSwitch: false))

            let step3 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotifications137Step3),
                                          action: .toggle(description: .enableSettingsExposureNotifications137Step3ActionTitle))

            let step4 = EnableSettingStep(description: fromHtml(.enableSettingsExposureNotifications137Step4),
                                          action: .linkCell(description: .enableSettingsExposureNotifications137Step4ActionTitle))

            return .init(title: .enableSettingsExposureNotificationsTitle,
                         steps: [step1, step2, step3, step4],
                         action: .openSettings,
                         actionTitle: .enableSettingsExposureNotificationsAction)
        }
    }

    static var enableBluetooth: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

            let step1 = EnableSettingStep(description: fromHtml(.enableBluetoothSettingTitleRow1),
                                          action: .custom(image: .settingsIcon, description: .enableBluetoothSettingTitleSettingRow1, showChevron: false, showSwitch: false))
            let step2 = EnableSettingStep(description: fromHtml(.enableBluetoothSettingTitleRow2),
                                          action: .custom(image: .bluetoothIcon, description: .enableBluetoothSettingTitleSettingRow2, showChevron: true, showSwitch: false))
            let step3 = EnableSettingStep(description: fromHtml(.enableBluetoothSettingTitleRow3),
                                          action: .toggle(description: .enableBluetoothSettingTitleSettingRow3))

            return .init(title: .enableSettingsBluetoothTitle,
                         steps: [step1, step2, step3],
                         action: nil,
                         actionTitle: .enableSettingsBluetoothAction)
        }
    }
    
    static var connectToInternet: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

            let step1 = EnableSettingStep(description: fromHtml(.enableInternetTitleRow1), action: nil)
            let step2 = EnableSettingStep(description: fromHtml(.enableInternetSettingTitleRow2), action: .custom(image: .mobileData, description: .enableInternetSettingTitleSettingRow2, showChevron: false, showSwitch: true))

            return .init(title: .enableSettingsInternetTitle,
                         introduction: fromHtml(.enableSettingsInternetIntroduction),
                         stepTitle: .makeFromHtml(text: .enableSettingsInternetStepTitle, font: theme.fonts.title2, textColor: .black),
                         footer: fromHtml(.enableInternetFooter),
                         steps: [step1, step2],
                         action: .openSettings,
                         actionTitle: .enableInternetOpenSettingsButton)
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
                                          action: .custom(image: .notification, description: .enableSettingsLocalNotificationsStep2ActionTitle, showChevron: true, showSwitch: false))
            let step3 = EnableSettingStep(description: fromHtml(.enableSettingsLocalNotificationsStep3),
                                          action: .toggle(description: .enableSettingsLocalNotificationsStep3ActionTitle))

            return .init(title: .enableSettingsLocalNotificationsTitle,
                         steps: [step1, step2, step3],
                         action: .openSettings,
                         actionTitle: .enableSettingsLocalNotificationsAction)
        }
    }

    static var updateOperatingSystem: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

            let step1 = EnableSettingStep(description: fromHtml(.updateSoftwareOSDetailStep1),
                                          action: .custom(image: .settingsIcon, description: .updateSoftwareOSDetailStep1Detail, showChevron: false, showSwitch: false))
            let step2 = EnableSettingStep(description: fromHtml(.updateSoftwareOSDetailStep2),
                                          action: .custom(image: .settingsPlain, description: .updateSoftwareOSDetailStep2Detail, showChevron: true, showSwitch: false))
            let step3 = EnableSettingStep(description: fromHtml(.updateSoftwareOSDetailStep3),
                                          action: .custom(image: nil, description: .updateSoftwareOSDetailStep3Detail, showChevron: true, showSwitch: false))

            let step4 = EnableSettingStep(description: fromHtml(.updateSoftwareOSDetailStep4),
                                          action: nil)

            return .init(title: .updateSoftwareOSDetailTitle,
                         steps: [step1, step2, step3, step4],
                         action: nil,
                         actionTitle: nil)
        }
    }

    static var enableMobileDataUsage: (Theme) -> EnableSettingModel {
        return { theme in
            let fromHtml: (String) -> NSAttributedString = { .makeFromHtml(text: $0,
                                                                           font: theme.fonts.body,
                                                                           textColor: .black,
                                                                           textAlignment: Localization.isRTL ? .right : .left) }

            let step1 = EnableSettingStep(description: fromHtml(.moreInformationSettingsStep1),
                                          action: nil)
            let step2 = EnableSettingStep(description: fromHtml(.moreInformationSettingsStep2),
                                          action: .custom(image: .mobileData, description: .moreInformationSettingsStep2RowTitle, showChevron: false, showSwitch: true))
            return .init(title: .moreInformationSettingsTitle,
                         steps: [step1, step2],
                         action: nil,
                         actionTitle: .moreInformationSettingsButton)
        }
    }
}

struct EnableSettingStep {
    enum Action {
        case linkCell(description: String)
        case toggle(description: String)
        case custom(image: UIImage?, description: String, showChevron: Bool, showSwitch: Bool)
    }

    let description: NSAttributedString
    let action: Action?
}

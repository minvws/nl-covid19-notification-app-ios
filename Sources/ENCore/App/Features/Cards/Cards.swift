/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

struct CardAction {
    let action: () -> ()

    static var openSettings: CardAction {
        return .init {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
        }
    }

    static func custom(action: @escaping () -> ()) -> CardAction {
        return .init(action: action)
    }
}

struct Card {
    let title: NSAttributedString
    let message: NSAttributedString
    let action: CardAction
    let actionTitle: String

    static func bluetoothOff(theme: Theme) -> Card {
        let title = Localization.string(for: "cards.bluetoothOff.title")
        let content = Localization.string(for: "cards.bluetoothOff.content")
        let action = Localization.string(for: "cards.bluetoothOff.action")

        return Card(title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray),
                    action: .openSettings,
                    actionTitle: action)
    }

    static func exposureOff(theme: Theme) -> Card {
        let title = Localization.string(for: "cards.exposureOff.title")
        let content = Localization.string(for: "cards.exposureOff.content")
        let action = Localization.string(for: "cards.exposureOff.action")

        return Card(title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray),
                    action: .openSettings,
                    actionTitle: action)
    }

    static func noInternet(theme: Theme, retryHandler: @escaping () -> ()) -> Card {
        let title = Localization.string(for: "cards.noInternet.title")
        let content = Localization.string(for: "cards.noInternet.content")
        let action = Localization.string(for: "cards.noInternet.action")

        return Card(title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray),
                    action: .custom(action: retryHandler),
                    actionTitle: action)
    }

    static func noLocalNotifications(theme: Theme) -> Card {
        let title = Localization.string(for: "cards.notificationsOff.title")
        let content = Localization.string(for: "cards.notificationsOff.content")
        let action = Localization.string(for: "cards.notificationsOff.action")

        return Card(title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray),
                    action: .openSettings,
                    actionTitle: action)
    }
}

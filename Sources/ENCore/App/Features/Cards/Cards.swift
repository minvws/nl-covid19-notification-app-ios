/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum CardAction {
    case openEnableSetting(EnableSetting)
    case custom(action: () -> ())
}

struct Card {
    let title: NSAttributedString
    let message: NSAttributedString
    let action: CardAction
    let actionTitle: String

    static func bluetoothOff(theme: Theme) -> Card {
        let title: String = .cardsBluetoothOffTitle
        let content: String = .cardsBluetoothOffContent
        let action: String = .cardsBluetoothOffAction

        return Card(title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray),
                    action: .openEnableSetting(.enableBluetooth),
                    actionTitle: action)
    }

    static func exposureOff(theme: Theme) -> Card {
        let title: String = .cardsExposureOffTitle
        let content: String = .cardsExposureOffContent
        let action: String = .cardsExposureOffAction

        return Card(title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray),
                    action: .openEnableSetting(.enableExposureNotifications),
                    actionTitle: action)
    }

    static func noInternet(theme: Theme, retryHandler: @escaping () -> ()) -> Card {
        let title: String = .cardsNoInternetTitle
        let content: String = .cardsNoInternetContent
        let action: String = .cardsNoInternetAction

        return Card(title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray),
                    action: .custom(action: retryHandler),
                    actionTitle: action)
    }

    static func noLocalNotifications(theme: Theme) -> Card {
        let title: String = .cardsNotificationsOffTitle
        let content: String = .cardsNotificationsOffContent
        let action: String = .cardsNotificationsOffAction

        return Card(title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray),
                    action: .openEnableSetting(.enableLocalNotifications),
                    actionTitle: action)
    }
}

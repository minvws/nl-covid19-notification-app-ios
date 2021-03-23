/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

enum CardAction {
    case openEnableSetting(EnableSetting)
    case openWebsite(url: URL)
    case dismissAnnouncement(_ announcement: Announcement)
    case custom(action: () -> ())
    case unpause
}

enum CardIcon {
    case info
    case warning
    case paused

    var image: UIImage? {
        switch self {
        case .info: return Image.named("InfoBordered")
        case .warning: return Image.named("StatusInactive")
        case .paused: return Image.named("StatusPaused")
        }
    }
}

struct Card {

    let icon: CardIcon
    let title: NSAttributedString
    let message: NSAttributedString
    let action: CardAction
    let actionTitle: String
    let secondaryAction: CardAction?
    let secondaryActionTitle: String?

    init(icon: CardIcon,
         title: NSAttributedString,
         message: NSAttributedString,
         action: CardAction,
         actionTitle: String,
         secondaryAction: CardAction? = nil,
         secondaryActionTitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
        self.secondaryAction = secondaryAction
        self.secondaryActionTitle = secondaryActionTitle
    }

    static func paused(theme: Theme, pauseTimeElapsed: Bool, content: NSAttributedString) -> Card {
        let title: String = pauseTimeElapsed ? .statusCardManualUnpauseTitle : .statusPausedCardTitle
        let action: String = .statusAppStateCardButton
        let icon: CardIcon = pauseTimeElapsed ? .warning : .paused

        return Card(icon: icon, title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black, textAlignment: Localization.isRTL ? .right : .left),
                    message: content,
                    action: .unpause,
                    actionTitle: action)
    }

    static func bluetoothOff(theme: Theme) -> Card {
        let title: String = .statusAppStatePartlyInactiveTitle
        let content: String = .statusAppStateCardBluetooth
        let action: String = .statusAppStateCardBluetoothButton

        return Card(icon: .warning, title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black, textAlignment: Localization.isRTL ? .right : .left),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray, textAlignment: Localization.isRTL ? .right : .left),
                    action: .openEnableSetting(.enableBluetooth),
                    actionTitle: action)
    }

    static func exposureOff(theme: Theme) -> Card {
        let title: String = .cardsExposureOffTitle
        let content: String = .cardsExposureOffContent
        let action: String = .cardsExposureOffAction

        return Card(icon: .warning, title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black, textAlignment: Localization.isRTL ? .right : .left),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray, textAlignment: Localization.isRTL ? .right : .left),
                    action: .openEnableSetting(.enableExposureNotifications),
                    actionTitle: action)
    }

    static func noInternet(theme: Theme, retryHandler: @escaping () -> ()) -> Card {
        let title: String = .cardsNoInternetTitle
        let content: String = .cardsNoInternetContent
        let action: String = .cardsNoInternetAction

        return Card(icon: .warning, title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black, textAlignment: Localization.isRTL ? .right : .left),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray, textAlignment: Localization.isRTL ? .right : .left),
                    action: .custom(action: retryHandler),
                    actionTitle: action)
    }

    static func noLocalNotifications(theme: Theme) -> Card {
        let title: String = .cardsNotificationsOffTitle
        let content: String = .cardsNotificationsOffContent
        let action: String = .cardsNotificationsOffAction

        return Card(icon: .warning, title: .makeFromHtml(text: title, font: theme.fonts.title3, textColor: .black, textAlignment: Localization.isRTL ? .right : .left),
                    message: .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray, textAlignment: Localization.isRTL ? .right : .left),
                    action: .openEnableSetting(.enableLocalNotifications),
                    actionTitle: action)
    }
}

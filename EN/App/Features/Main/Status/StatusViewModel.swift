/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit

struct StatusViewIcon {
    let color: UIColor
    let icon: UIImage?

    static let ok = StatusViewIcon(color: .okGreen, icon: UIImage(named: "StatusIconOk"))
    static let notified = StatusViewIcon(color: .notifiedRed, icon: UIImage(named: "StatusIconNotified"))
//    case warning
//    case pause
//    case lock
}

struct StatusViewButtonModel {
    let title: String
    let style: Button.ButtonType
    let action: Action

    enum Action {
        case explainRisk
        case removeNotification
        case turnOnApp
    }

    static let moreInfo = StatusViewButtonModel(
        title: "Wat moet ik nu doen?",
        style: .primary,
        action: .explainRisk
    )

    static let removeNotification = StatusViewButtonModel(
        title: "Melding verwijderen",
        style: .secondary,
        action: .removeNotification
    )

}

struct StatusCardViewModel {
    let icon: StatusViewIcon
    let title: NSAttributedString
    let description: NSAttributedString
    let button: StatusViewButtonModel

    static let inactive = StatusCardViewModel(
        icon: StatusViewIcon(color: .inactiveOrange, icon: UIImage(named: "StatusIconNotified")),
        title: .init(string: "App is niet actief"),
        description: .init(string: "Hier moet nog een tekst komen dat uitlegt dat Blootstelling uitstaat en dat Bluetooth ook uitstaat."),
        button: StatusViewButtonModel(
            title: "App aanzetten",
            style: .primary,
            action: .turnOnApp
        )
    )
}

struct StatusViewModel {
    var icon: StatusViewIcon
    var title: NSAttributedString
    var description: NSAttributedString
    var buttons: [StatusViewButtonModel]
    var card: StatusCardViewModel?
    var footer: NSAttributedString?
    var shouldShowHideMessage: Bool
    var gradientColor: UIColor
    var showScene: Bool

    func with(card: StatusCardViewModel?? = nil) -> Self {
        var result = self
        if let card = card {
            result.card = card
        }
        return result
    }

}

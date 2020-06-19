/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

struct StatusViewIcon {
    let color: ThemeColor
    let icon: UIImage?

    static let ok = StatusViewIcon(color: \.ok, icon: Image.named("StatusIconOk"))
    static let notified = StatusViewIcon(color: \.notified, icon: Image.named("StatusIconNotified"))
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
        icon: StatusViewIcon(color: \.inactive, icon: Image.named("StatusIconNotified")),
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
    var gradientColor: ThemeColor
    var showScene: Bool

    func with(card: StatusCardViewModel?? = nil) -> Self {
        var result = self
        if let card = card {
            result.card = card
        }
        return result
    }

    static let active = StatusViewModel(
        icon: .ok,
        title: .init(string: "De app is actief"),
        description: .init(string: "Je krijgt een melding nadat je extra kans op besmetting hebt gelopen."),
        buttons: [],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.statusGradientActive,
        showScene: true
    )

    static let notified = StatusViewModel(
        icon: .notified,
        title: .init(string: "Je hebt extra kans op besmetting gelopen"),
        description: .init(string: "Je bent op maandag 1 juni dicht bij iemand geweest die daarna positief is getest op het coronavirus."),
        buttons: [.moreInfo, .removeNotification],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.statusGradientNotified,
        showScene: false
    )
}

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
        title: Localization.string(for: "status.notified.moreInfo"),
        style: .secondary,
        action: .explainRisk
    )

    static let removeNotification = StatusViewButtonModel(
        title: Localization.string(for: "status.notified.removeNotification"),
        style: .tertiary,
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
        title: .init(string: Localization.string(for: "status.appState")),
        description: .init(string: Localization.string(for: "status.active.description")),
        buttons: [],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.statusGradientActive,
        showScene: true
    )

    static let notified = StatusViewModel(
        icon: .notified,
        title: .init(string: Localization.string(for: "status.appState")),
        description: .init(string: Localization.string(for: "status.notified.description")), // TODO: this needs to be dynamic
        buttons: [.moreInfo, .removeNotification],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.statusGradientNotified,
        showScene: false
    )
}

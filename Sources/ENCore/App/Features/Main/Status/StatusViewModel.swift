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
    static let inactive = StatusViewIcon(color: \.inactive, icon: Image.named("StatusInactive"))
}

struct StatusViewButtonModel {
    let title: String
    let style: Button.ButtonType
    let action: Action

    enum Action {
        case explainRisk(Date)
        case removeNotification
        case updateAppSettings
        case tryAgain
    }

    static func moreInfo(date: Date) -> StatusViewButtonModel {
        StatusViewButtonModel(
            title: Localization.string(for: "status.notified.moreInfo"),
            style: .warning,
            action: .explainRisk(date)
        )
    }

    static let removeNotification = StatusViewButtonModel(
        title: Localization.string(for: "status.notified.removeNotification"),
        style: .tertiary,
        action: .removeNotification
    )

    static let enableSettings = StatusViewButtonModel(
        title: Localization.string(for: "status.appState.card.button"),
        style: .primary,
        action: .updateAppSettings
    )

    static let tryAgain = StatusViewButtonModel(
        title: Localization.string(for: "status.appState.card.try_again"),
        style: .primary,
        action: .updateAppSettings
    )
}

struct StatusCardViewModel {
    let icon: StatusViewIcon
    let title: NSAttributedString
    let description: NSAttributedString
    let button: StatusViewButtonModel

    static let inactive = StatusCardViewModel(
        icon: StatusViewIcon(color: \.inactive, icon: Image.named("StatusInactive")),
        title: .init(string: Localization.string(for: "status.appState.card.title")),
        description: .init(string: Localization.string(for: "status.appState.card.description", ["CoronaMelder"])),
        button: StatusViewButtonModel.enableSettings
    )

    static let inactiveTryAgain = StatusCardViewModel(
        icon: StatusViewIcon(color: \.inactive, icon: Image.named("StatusInactive")),
        title: .init(string: Localization.string(for: "status.appState.card.title")),
        description: .init(string: Localization.string(for: "status.appState.inactive.no_recent_updates.description")),
        button: StatusViewButtonModel.tryAgain
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

    static func activeWithNotified(date: Date) -> StatusViewModel {
        let description = Localization
            .string(for: "status.notified.description", [timeAgo(from: date)])
            .capitalizedFirstLetterOnly

        return StatusViewModel(
            icon: .notified,
            title: .init(string: Localization.string(for: "status.appState")),
            description: .init(string: description),
            buttons: [.moreInfo(date: date), .removeNotification],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientNotified,
            showScene: false
        )
    }

    static let activeWithNotNotified = StatusViewModel(
        icon: .ok,
        title: .init(string: Localization.string(for: "status.appState")),
        description: .init(string: Localization.string(for: "status.active.description", ["CoronaMelder"])),
        buttons: [],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.statusGradientActive,
        showScene: true
    )

    static func inactiveWithNotified(date: Date) -> StatusViewModel {
        let description = Localization
            .string(for: "status.notified.description", [timeAgo(from: date)])
            .capitalizedFirstLetterOnly

        return StatusViewModel(
            icon: .notified,
            title: .init(string: Localization.string(for: "status.appState")),
            description: .init(string: description),
            buttons: [.moreInfo(date: date), .removeNotification],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientNotified,
            showScene: false
        )
    }

    static let inactiveWithNotNotified = StatusViewModel(
        icon: .inactive,
        title: .init(string: Localization.string(for: "status.appState.inactive.title")),
        description: .init(string: Localization.string(for: "status.appState.inactive.description", ["CoronaMelder"])),
        buttons: [.enableSettings],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.inactive,
        showScene: false
    )

    static let inactiveTryAgainWithNotNotified = StatusViewModel(
        icon: .inactive,
        title: .init(string: Localization.string(for: "status.appState.inactive.title")),
        description: .init(string: Localization.string(for: "status.appState.inactive.no_recent_updates.description")),
        buttons: [.tryAgain],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.inactive,
        showScene: false
    )

    static func timeAgo(from: Date) -> String {
        let now = currentDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let dateString = dateFormatter.string(from: from)

        if let days = from.days(sinceDate: now), days > 0 {
            return Localization.string(for: "status.notified.description_days", ["\(days)", dateString])
        }
        if let hours = from.hours(sinceDate: now), hours > 0 {
            return Localization.string(for: "status.notified.description_hours", ["\(hours)", dateString])
        }
        return Localization.string(for: "status.notified.description_none", [dateString])
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

struct StatusViewIcon {
    let color: ThemeColor
    let icon: UIImage?

    static let ok = StatusViewIcon(color: \.ok, icon: .statusIconOk)
    static let notified = StatusViewIcon(color: \.notified, icon: .statusIconNotified)
    static let inactive = StatusViewIcon(color: \.inactive, icon: .statusInactive)
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
            title: .statusNotifiedMoreInfo,
            style: .warning,
            action: .explainRisk(date)
        )
    }

    static let removeNotification = StatusViewButtonModel(
        title: .statusNotifiedRemoveNotification,
        style: .tertiary,
        action: .removeNotification
    )

    static let enableSettings = StatusViewButtonModel(
        title: .statusAppStateCardButton,
        style: .primary,
        action: .updateAppSettings
    )

    static let tryAgain = StatusViewButtonModel(
        title: .statusAppStateCardTryAgain,
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
        icon: StatusViewIcon(color: \.inactive, icon: .statusInactive),
        title: .init(string: .statusAppStateCardTitle),
        description: .init(string: String(format: .statusAppStateCardDescription)),
        button: StatusViewButtonModel.enableSettings
    )

    static let inactiveTryAgain = StatusCardViewModel(
        icon: StatusViewIcon(color: \.inactive, icon: .statusInactive),
        title: .init(string: .statusAppStateCardTitle),
        description: .init(string: .statusAppStateInactiveNoRecentUpdatesDescription),
        button: StatusViewButtonModel.tryAgain
    )
}

struct StatusViewModel {
    var icon: StatusViewIcon
    var title: NSAttributedString
    var description: NSAttributedString
    var buttons: [StatusViewButtonModel]
    var cardType: CardType?
    var footer: NSAttributedString?
    var shouldShowHideMessage: Bool
    var gradientColor: ThemeColor
    var showScene: Bool
    var showClouds: Bool

    func with(cardType: CardType?) -> Self {
        var result = self
        if let cardType = cardType {
            result.cardType = cardType
        }
        return result
    }

    static func activeWithNotified(date: Date) -> StatusViewModel {
        let description = String(format: .statusNotifiedDescription, timeAgo(from: date))
            .capitalizedFirstLetterOnly

        return StatusViewModel(
            icon: .notified,
            title: .init(string: .statusAppState),
            description: .init(string: description),
            buttons: [.moreInfo(date: date), .removeNotification],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientNotified,
            showScene: false,
            showClouds: false
        )
    }

    static let activeWithNotNotified = StatusViewModel(
        icon: .ok,
        title: .init(string: .statusAppState),
        description: .init(string: String(format: .statusActiveDescription)),
        buttons: [],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.statusGradientActive,
        showScene: true,
        showClouds: true
    )

    static func inactiveWithNotified(date: Date) -> StatusViewModel {
        let description = String(format: .statusNotifiedDescription, timeAgo(from: date))
            .capitalizedFirstLetterOnly

        return StatusViewModel(
            icon: .notified,
            title: .init(string: .statusAppState),
            description: .init(string: description),
            buttons: [.moreInfo(date: date), .removeNotification],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientNotified,
            showScene: false,
            showClouds: false
        )
    }

    static let inactiveWithNotNotified = StatusViewModel(
        icon: .inactive,
        title: .init(string: .statusAppStateInactiveTitle),
        description: .init(string: String(format: .statusAppStateInactiveDescription)),
        buttons: [.enableSettings],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.inactive,
        showScene: false,
        showClouds: false
    )

    static let inactiveTryAgainWithNotNotified = StatusViewModel(
        icon: .inactive,
        title: .init(string: .statusAppStateInactiveTitle),
        description: .init(string: .statusAppStateInactiveNoRecentUpdatesDescription),
        buttons: [.tryAgain],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.inactive,
        showScene: false,
        showClouds: false
    )

    static func timeAgo(from: Date) -> String {
        let now = currentDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let dateString = dateFormatter.string(from: from)

        if let days = from.days(sinceDate: now), days > 0 {
            return String(format: .statusNotifiedDescriptionDays, "\(days)", dateString)
        }
        if let hours = from.hours(sinceDate: now), hours > 0 {
            return String(format: .statusNotifiedDescriptionHours, "\(hours)", dateString)
        }
        return String(format: .statusNotifiedDescriptionNone, dateString)
    }
}

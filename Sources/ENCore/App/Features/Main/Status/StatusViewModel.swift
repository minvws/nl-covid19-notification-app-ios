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
    let accessibilityLabel: String

    static let ok = StatusViewIcon(color: \.ok, icon: .statusIconOk, accessibilityLabel: .statusIconAccessibilityOk)
    static let notified = StatusViewIcon(color: \.notified, icon: .statusIconNotified, accessibilityLabel: .statusIconAccessibilityNotified)
    static let inactive = StatusViewIcon(color: \.inactive, icon: .statusIconInactive, accessibilityLabel: .statusIconAccessibilityInactive)
    static let paused = StatusViewIcon(color: \.inactiveGray, icon: .statusIconPaused, accessibilityLabel: .statusIconAccessibilityPaused)
}

struct StatusViewButtonModel {
    let title: String
    let style: Button.ButtonType
    let action: Action

    enum Action {
        case explainRisk
        case removeNotification(String)
        case updateAppSettings
        case tryAgain
        case unpause
    }

    static func moreInfo() -> StatusViewButtonModel {
        StatusViewButtonModel(
            title: .statusNotifiedMoreInfo,
            style: .warning,
            action: .explainRisk
        )
    }

    static func removeNotification(title: String) -> StatusViewButtonModel {
        StatusViewButtonModel(
            title: .statusNotifiedRemoveNotification,
            style: .tertiary,
            action: .removeNotification(title)
        )
    }

    static let enableSettings = StatusViewButtonModel(
        title: .statusAppStateCardButton,
        style: .primary,
        action: .updateAppSettings
    )

    static let enableBluetooth = StatusViewButtonModel(
        title: .statusAppStateCardBluetoothButton,
        style: .primary,
        action: .updateAppSettings
    )

    static let unpause = StatusViewButtonModel(
        title: .statusAppStateCardButton,
        style: .primary,
        action: .unpause
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
        icon: StatusViewIcon(color: \.inactive, icon: .statusInactive, accessibilityLabel: .statusIconAccessibilityInactive),
        title: .init(string: .statusAppStateCardTitle),
        description: .init(string: String(format: .statusAppStateCardDescription)),
        button: StatusViewButtonModel.enableSettings
    )

    static let inactiveTryAgain = StatusCardViewModel(
        icon: StatusViewIcon(color: \.inactive, icon: .statusInactive, accessibilityLabel: .statusIconAccessibilityInactive),
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
    var footer: NSAttributedString?
    var shouldShowHideMessage: Bool
    var gradientColor: ThemeColor
    var showScene: Bool
    var showClouds: Bool
    var showEmitter: Bool

    static func activeWithNotified(date: Date) -> StatusViewModel {
        let description = timeAgo(from: date)
            .capitalizedFirstLetterOnly

        return StatusViewModel(
            icon: .notified,
            title: .init(string: .messageDefaultTitle),
            description: .init(string: description),
            buttons: [.moreInfo(), .removeNotification(title: description)],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientNotified,
            showScene: false,
            showClouds: false,
            showEmitter: true
        )
    }

    static func activeWithNotNotified(showScene: Bool) -> StatusViewModel {

        return StatusViewModel(
            icon: .ok,
            title: .init(string: .statusAppState),
            description: .init(string: String(format: .statusActiveDescription)),
            buttons: [],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientActive,
            showScene: showScene,
            showClouds: true,
            showEmitter: true
        )
    }

    static func activeWithNotifiedThresholdDaysAgoCard(showScene: Bool) -> StatusViewModel {

        return StatusViewModel(
            icon: .ok,
            title: .init(string: .statusAppState),
            description: .init(string: String(format: .statusActiveDescription)),
            buttons: [],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientActive,
            showScene: showScene,
            showClouds: true,
            showEmitter: true
        )
    }

    static func inactiveWithNotified(date: Date) -> StatusViewModel {
        let description = timeAgo(from: date)
            .capitalizedFirstLetterOnly

        return StatusViewModel(
            icon: .notified,
            title: .init(string: .messageDefaultTitle),
            description: .init(string: description),
            buttons: [.moreInfo(), .removeNotification(title: description)],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientNotified,
            showScene: false,
            showClouds: false,
            showEmitter: true
        )
    }

    static func pausedWithNotNotified(theme: Theme, pauseEndDate: Date) -> StatusViewModel {

        let description = PauseController.getPauseCountdownString(theme: theme, endDate: pauseEndDate, center: true, emphasizeTime: true)

        let title: String = pauseEndDate.isBefore(currentDate()) ? .statusPauseEndedTitle : .statusPausedTitle

        return StatusViewModel(
            icon: .paused,
            title: .init(string: title),
            description: description,
            buttons: [.unpause],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.statusGradientPaused,
            showScene: false,
            showClouds: false,
            showEmitter: false
        )
    }

    static let inactiveWithNotNotified = StatusViewModel(
        icon: .inactive,
        title: .init(string: .statusAppStateInactiveTitle),
        description: .init(string: .statusAppStateInactiveDescription),
        buttons: [.enableSettings],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.lightOrange,
        showScene: false,
        showClouds: false,
        showEmitter: true
    )

    static func bluetoothInactiveWithNotNotified(theme: Theme) -> StatusViewModel {
        StatusViewModel(
            icon: .inactive,
            title: .init(string: .statusAppStatePartlyInactiveTitle),
            description: .makeFromHtml(text: .statusAppStatePartlyInactiveBluetoothDescription, font: theme.fonts.body, textColor: .black, textAlignment: .center),
            buttons: [.enableBluetooth],
            footer: nil,
            shouldShowHideMessage: false,
            gradientColor: \.lightOrange,
            showScene: false,
            showClouds: false,
            showEmitter: true
        )
    }

    static let inactiveTryAgainWithNotNotified = StatusViewModel(
        icon: .inactive,
        title: .init(string: .statusAppStateInactiveTitle),
        description: .init(string: .statusAppStateInactiveNoRecentUpdatesDescription),
        buttons: [.tryAgain],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: \.lightOrange,
        showScene: false,
        showClouds: false,
        showEmitter: true
    )

    static func timeAgo(from: Date) -> String {
        let now = currentDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full

        let dateString = dateFormatter.string(from: from)
        let days = now.days(sinceDate: from) ?? 0

        return .statusNotifiedDescription(dateString, two: .statusNotifiedDaysAgo(days: days))
    }
}

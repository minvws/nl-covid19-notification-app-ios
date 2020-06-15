/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

struct StatusViewIcon {
    enum Status {
        case ok
        case notified
        case inactive
    }
    
    let color: UIColor
    let icon: UIImage?
    
    // MARK: - Init
    
    init(theme: Theme, status: Status) {
        switch status {
        case .ok:
            self.color = theme.colors.ok
            self.icon = UIImage(named: "StatusIconOk")
        case .notified:
            self.color = theme.colors.notified
            self.icon = UIImage(named: "StatusIconNotified")
        case .inactive:
            self.color = theme.colors.inactive
            self.icon = UIImage(named: "StatusIconNotified")
        }
    }
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
    
    // MARK: - Init
    
    init(theme: Theme) {
        self.icon = StatusViewIcon(theme: theme, status: .inactive)
        self.title = .init(string: "App is niet actief")
        self.description = .init(string: "Hier moet nog een tekst komen dat uitlegt dat Blootstelling uitstaat en dat Bluetooth ook uitstaat.")
        self.button = StatusViewButtonModel(title: "App aanzetten",
                                            style: .primary,
                                            action: .turnOnApp)
    }
}

struct StatusViewModel {
    enum Status {
        case active
        case notified
    }
    
    var icon: StatusViewIcon
    var title: NSAttributedString
    var description: NSAttributedString
    var buttons: [StatusViewButtonModel]
    var card: StatusCardViewModel?
    var footer: NSAttributedString?
    var shouldShowHideMessage: Bool
    var gradientColor: UIColor
    var showScene: Bool
    
    init(theme: Theme, status: Status) {
        switch status {
        case .active:
            self.init(
                theme: theme,
                icon: .ok,
                title: .init(string: "De app is actief"),
                description: .init(string: "Je krijgt een melding nadat je extra kans op besmetting hebt gelopen."),
                buttons: [],
                footer: nil,
                shouldShowHideMessage: false,
                gradientColor: theme.colors.statusGradientActive,
                showScene: true
            )
        case .notified:
            self.init(
                theme: theme,
                icon: .notified,
                title: .init(string: "Je hebt extra kans op besmetting gelopen"),
                description: .init(string: "Je bent op maandag 1 juni dicht bij iemand geweest die daarna positief is getest op het coronavirus."),
                buttons: [.moreInfo, .removeNotification],
                footer: nil,
                shouldShowHideMessage: false,
                gradientColor: theme.colors.statusGradienNotified,
                showScene: false
            )
        }
    }
    
    init(theme: Theme,
         icon: StatusViewIcon.Status,
         title: NSAttributedString,
         description: NSAttributedString,
         buttons: [StatusViewButtonModel],
         card: StatusCardViewModel? = nil,
         footer: NSAttributedString? = nil,
         shouldShowHideMessage: Bool,
         gradientColor: UIColor,
         showScene: Bool) {
        self.icon = StatusViewIcon(theme: theme, status: icon)
        self.title = title
        self.description = description
        self.buttons = buttons
        self.card = card
        self.footer = footer
        self.shouldShowHideMessage = shouldShowHideMessage
        self.gradientColor = gradientColor
        self.showScene = showScene
    }

    func with(card: StatusCardViewModel?? = nil) -> Self {
        var result = self
        if let card = card {
            result.card = card
        }
        return result
    }
}

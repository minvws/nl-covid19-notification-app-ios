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

struct StatusViewModel {
    var icon: StatusViewIcon
    var title: NSAttributedString
    var description: NSAttributedString
    var buttons: [StatusViewButtonModel]
    var footer: NSAttributedString?
    var shouldShowHideMessage: Bool
}

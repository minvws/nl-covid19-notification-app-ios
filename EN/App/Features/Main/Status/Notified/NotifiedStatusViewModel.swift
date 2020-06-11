/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// Represents the person is notified about an exposure
//struct NotifiedStatusViewModel: StatusViewModel {
//    let icon: StatusViewIcon = .warning
//    let title: NSAttributedString = .init(string: "Notified")
//    let description: NSAttributedString = .init(string: "Description")
//    let button: StatusViewButtonModel? = nil
//    let footer: NSAttributedString? = nil
//    let shouldShowHideMessage: Bool = false
//}

extension StatusViewModel {
    static let notified = StatusViewModel(
        icon: .notified,
        title: .init(string: "Je hebt extra kans op besmetting gelopen"),
        description: .init(string: "Je bent op maandag 1 juni dicht bij iemand geweest die daarna positief is getest op het coronavirus."),
        buttons: [.moreInfo, .removeNotification],
        footer: nil,
        shouldShowHideMessage: false
    )
}

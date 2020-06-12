/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// Represents the Active App State
extension StatusViewModel {
    static let active = StatusViewModel(
        icon: .ok,
        title: .init(string: "De app is actief"),
        description: .init(string: "Je krijgt een melding nadat je extra kans op besmetting hebt gelopen."),
        buttons: [],
        footer: nil,
        shouldShowHideMessage: false,
        gradientColor: .statusGradientBlue,
        showScene: true
    )
}

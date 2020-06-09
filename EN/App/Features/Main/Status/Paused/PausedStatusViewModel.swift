/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// Represents the app is paused state
struct PausedStatusViewModel: StatusViewModel {
    let icon: StatusViewIcon = .pause
    let title: NSAttributedString = .init(string: "Paused")
    let description: NSAttributedString = .init(string: "Description")
    let button: StatusViewButtonModel? = nil
    let footer: NSAttributedString? = nil
    let shouldShowHideMessage: Bool = false
}

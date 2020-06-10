/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit

enum StatusViewIcon {
    case ok
    case warning
    case pause
    case lock
}

struct StatusViewButtonModel {
    let title: String
    let action: () -> ()
}

protocol StatusViewModel {
    var icon: StatusViewIcon { get }
    var title: NSAttributedString { get }
    var description: NSAttributedString { get }
    var button: StatusViewButtonModel? { get }
    var footer: NSAttributedString? { get }
    var shouldShowHideMessage: Bool { get }
}

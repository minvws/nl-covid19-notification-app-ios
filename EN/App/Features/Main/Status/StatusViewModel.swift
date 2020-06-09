//
//  StatusViewModel.swift
//  EN
//
//  Created by Robin van Dijke on 09/06/2020.
//

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

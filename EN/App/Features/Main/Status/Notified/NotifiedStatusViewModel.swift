//
//  NotifiedStatusViewModel.swift
//  EN
//
//  Created by Robin van Dijke on 09/06/2020.
//

import Foundation

/// Represents the person is notified about an exposure
struct NotifiedStatusViewModel: StatusViewModel {
    let icon: StatusViewIcon = .warning
    let title: NSAttributedString = .init(string: "Notified")
    let description: NSAttributedString = .init(string: "Description")
    let button: StatusViewButtonModel? = nil
    let footer: NSAttributedString? = nil
    let shouldShowHideMessage: Bool = false
}

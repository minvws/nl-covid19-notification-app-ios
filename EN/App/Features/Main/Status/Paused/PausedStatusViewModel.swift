//
//  PausedStatusViewModel.swift
//  EN
//
//  Created by Robin van Dijke on 09/06/2020.
//

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

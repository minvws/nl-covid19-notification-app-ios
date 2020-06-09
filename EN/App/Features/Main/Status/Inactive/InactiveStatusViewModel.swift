//
//  InactiveStatusViewModel.swift
//  EN
//
//  Created by Robin van Dijke on 09/06/2020.
//

import Foundation

/// Represents the App is inactive state
struct InactiveStatusViewModel: StatusViewModel {
    let icon: StatusViewIcon = .warning
    let title: NSAttributedString = .init(string: "Inactive")
    let description: NSAttributedString = .init(string: "Description")
    let button: StatusViewButtonModel? = nil
    let footer: NSAttributedString? = nil
    let shouldShowHideMessage: Bool = false
}

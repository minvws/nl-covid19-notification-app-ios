//
//  ActiveStatusViewModel.swift
//  EN
//
//  Created by Robin van Dijke on 09/06/2020.
//

import Foundation

/// Represents the Active App State
struct ActiveStatusViewModel: StatusViewModel {
    let icon: StatusViewIcon = .ok
    let title: NSAttributedString = .init(string: "Active")
    let description: NSAttributedString = .init(string: "Description")
    let button: StatusViewButtonModel? = nil
    let footer: NSAttributedString? = nil
    let shouldShowHideMessage: Bool = false
}

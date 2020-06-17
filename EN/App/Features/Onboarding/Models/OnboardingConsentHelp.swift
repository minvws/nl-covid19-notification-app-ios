//
//  OnboardingConsentHelp.swift
//  EN
//
//  Created by Rob Mulder on 17/06/2020.
//

import UIKit

final class OnboardingConsentHelp: NSObject {

    var question: String
    var attributedTitle: NSAttributedString = NSAttributedString(string: "")
    var attributedAnswer: NSAttributedString = NSAttributedString(string: "")

    init(theme: Theme, question: String, answer: String) {

        self.question = question
        self.attributedTitle = .makeFromHtml(text: question, font: .boldSystemFont(ofSize: 22), textColor: theme.colors.gray)
        self.attributedAnswer = .makeFromHtml(text: answer, font: .systemFont(ofSize: 17), textColor: theme.colors.gray)
    }
}

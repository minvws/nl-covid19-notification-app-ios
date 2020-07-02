/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Lottie
import UIKit

final class OnboardingStep: NSObject {
    enum Illustration {
        case image(named: String)
        case animation(named: String, repeatFromFrame: Int? = nil)
    }

    var attributedTitle: NSAttributedString = NSAttributedString(string: "")
    var attributedContent: NSAttributedString = NSAttributedString(string: "")

    let illustration: Illustration
    var buttonTitle: String = ""
    var isExample: Bool = false

    init(theme: Theme,
         title: String,
         content: String,
         illustration: Illustration,
         buttonTitle: String,
         isExample: Bool) {

        self.illustration = illustration
        self.buttonTitle = buttonTitle
        self.isExample = isExample

        let attributedTitleString = NSMutableAttributedString()

        if isExample {
            attributedTitleString.append(.make(text: Localization.string(for: "example") + "\n\n", font: theme.fonts.subheadBold, textColor: theme.colors.warning))
        }

        attributedTitleString.append(.makeFromHtml(text: title, font: theme.fonts.title2, textColor: .black))

        self.attributedTitle = attributedTitleString
        self.attributedContent = .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray)
    }
}

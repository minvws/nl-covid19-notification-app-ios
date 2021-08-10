/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Lottie
import UIKit

final class OnboardingStep: NSObject {
    enum Illustration {
        case image(_ image: UIImage?)
        case animation(named: String, repeatFromFrame: Int? = nil, defaultFrame: CGFloat? = nil)
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
            attributedTitleString.append(.make(text: .example + "\n\n",
                                               font: theme.fonts.subheadBold,
                                               textColor: theme.colors.warningText,
                                               textAlignment: Localization.isRTL ? .right : .left))
        }

        attributedTitleString.append(.makeFromHtml(text: title,
                                                   font: theme.fonts.title2,
                                                   textColor: theme.colors.textPrimary,
                                                   textAlignment: Localization.isRTL ? .right : .left))

        self.attributedTitle = attributedTitleString
        self.attributedContent = .makeFromHtml(text: content,
                                               font: theme.fonts.body,
                                               textColor: theme.colors.textSecondary,
                                               textAlignment: Localization.isRTL ? .right : .left)
    }
}

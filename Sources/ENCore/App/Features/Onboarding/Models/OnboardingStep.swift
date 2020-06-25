/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Lottie
import UIKit

final class OnboardingStep: NSObject {

    var attributedTitle: NSAttributedString = NSAttributedString(string: "")
    var attributedContent: NSAttributedString = NSAttributedString(string: "")

    var image: UIImage?
    var animation: Animation?
    var hasAnimation: Bool { return self.animation != nil }
    var buttonTitle: String = ""
    var isExample: Bool = false

    init(theme: Theme,
         title: String,
         content: String,
         image: UIImage?,
         animationName: String?,
         buttonTitle: String,
         isExample: Bool) {

        self.image = image
        if let animationName = animationName {
            if let animation = LottieAnimation.named(animationName) {
                self.animation = animation
            }
        }
        self.buttonTitle = buttonTitle
        self.isExample = isExample

        let attributedTitleString = NSMutableAttributedString()

        if isExample {
            attributedTitleString.append(.make(text: Localization.string(for: "example") + "\n\n", font: theme.fonts.subhead, textColor: theme.colors.secondary))
        }

        attributedTitleString.append(.makeFromHtml(text: title, font: theme.fonts.title2, textColor: .black))

        self.attributedTitle = attributedTitleString
        self.attributedContent = .makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.gray)
    }
}

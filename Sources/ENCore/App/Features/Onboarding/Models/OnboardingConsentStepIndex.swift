/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Lottie
import UIKit

final class OnboardingConsentStep: NSObject {
    enum Index: Int {
        case en = 0
        case bluetooth
        case share
    }

    enum Illustration {
        case none
        case image(_ image: UIImage?)
        case animation(named: String, repeatFromFrame: Int? = nil, defaultFrame: CGFloat? = nil)
    }

    var step: Index
    var attributedTitle: NSAttributedString = NSAttributedString(string: "")
    var attributedContent: NSAttributedString = NSAttributedString(string: "")
    var illustration: Illustration
    var primaryButtonTitle: String = ""
    var secondaryButtonTitle: String?
    var hasNavigationBarSkipButton: Bool = false

    var hasSecondaryButton: Bool {
        return secondaryButtonTitle != nil
    }

    convenience init(step: Index,
                     theme: Theme,
                     title: String,
                     content: String,
                     illustration: Illustration,
                     primaryButtonTitle: String,
                     secondaryButtonTitle: String?,
                     hasNavigationBarSkipButton: Bool) {

        let attributedContent = NSAttributedString.makeFromHtml(text: content, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.isRTL ? .right : .left)

        self.init(step: step,
                  theme: theme,
                  title: title,
                  attributedContent: attributedContent,
                  illustration: illustration,
                  primaryButtonTitle: primaryButtonTitle,
                  secondaryButtonTitle: secondaryButtonTitle,
                  hasNavigationBarSkipButton: hasNavigationBarSkipButton)
    }

    convenience init(step: Index,
                     theme: Theme,
                     title: String,
                     content: String,
                     bulletItems: [String],
                     illustration: Illustration,
                     primaryButtonTitle: String,
                     secondaryButtonTitle: String?,
                     hasNavigationBarSkipButton: Bool) {

        let attributedContent = NSMutableAttributedString(attributedString: .makeFromHtml(text: content + "<br>",
                                                                                          font: theme.fonts.body,
                                                                                          textColor: theme.colors.textSecondary,
                                                                                          textAlignment: Localization.isRTL ? .right : .left))

        for bullet in NSAttributedString.bulletList(bulletItems, theme: theme, font: theme.fonts.body) {
            attributedContent.append("\n".attributed())
            attributedContent.append(bullet)
        }

        self.init(step: step,
                  theme: theme,
                  title: title,
                  attributedContent: attributedContent,
                  illustration: illustration,
                  primaryButtonTitle: primaryButtonTitle,
                  secondaryButtonTitle: secondaryButtonTitle,
                  hasNavigationBarSkipButton: hasNavigationBarSkipButton)
    }

    init(step: Index,
         theme: Theme,
         title: String,
         attributedContent: NSAttributedString,
         illustration: Illustration,
         primaryButtonTitle: String,
         secondaryButtonTitle: String?,
         hasNavigationBarSkipButton: Bool) {

        self.step = step
        self.illustration = illustration
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.hasNavigationBarSkipButton = hasNavigationBarSkipButton

        self.attributedTitle = .makeFromHtml(text: title, font: theme.fonts.title2, textColor: theme.colors.textPrimary, textAlignment: Localization.isRTL ? .right : .left)
        self.attributedContent = attributedContent
    }
}

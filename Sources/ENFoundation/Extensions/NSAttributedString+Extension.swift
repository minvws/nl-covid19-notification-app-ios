/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

public extension NSAttributedString {

    static func make(text: String, font: UIFont, textColor: UIColor, textAlignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil, underlineColor: UIColor? = nil) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        var attributes: [Key: Any] = [
            .foregroundColor: textColor,
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        if let underlineColor = underlineColor {
            attributes[.underlineColor] = underlineColor
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        return NSAttributedString(string: text, attributes: attributes)
    }

    static func makeFromHtml(text: String, font: UIFont, textColor: UIColor, textAlignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil, underlineColor: UIColor? = nil) -> NSAttributedString {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        var attributes: [Key: Any] = [
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        if let underlineColor = underlineColor {
            attributes[.underlineColor] = underlineColor
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        if let attributedTitle = try? NSMutableAttributedString(
            data: Data(text.utf8),
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil) {

            attributedTitle.addAttributes(
                attributes,
                range: NSRange(
                    location: 0,
                    length:
                    attributedTitle.length))

            let boldFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)
            let boldFont = boldFontDescriptor.map { UIFont(descriptor: $0, size: font.pointSize) }

            // replace default font with desired font - maintain bold style if possible
            let fullRange = NSRange(location: 0, length: attributedTitle.length)
            attributedTitle.enumerateAttribute(NSAttributedString.Key.font,
                                               in: fullRange,
                                               options: [])
            { value, range, finished in
                guard let currentFont = value as? UIFont else {
                    return
                }

                let newFont: UIFont

                if let boldFont = boldFont,
                    currentFont.fontDescriptor.symbolicTraits.contains(UIFontDescriptor.SymbolicTraits.traitBold) {
                    newFont = boldFont
                } else {
                    newFont = font
                }

                attributedTitle.removeAttribute(.font, range: range)
                attributedTitle.addAttribute(.font, value: newFont, range: range)
            }

            return attributedTitle
        }

        return NSAttributedString(string: text)
    }

    static func bulletList(_ stringList: [String],
                           theme: Theme,
                           font: UIFont,
                           bullet: String = "\u{2022}",
                           indentation: CGFloat = 16,
                           paragraphSpacing: CGFloat = 12) -> [NSAttributedString] {

        let textAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        let bulletAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: theme.colors.primary
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        let nonOptions = [NSTextTab.OptionKey: Any]()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation, options: nonOptions)
        ]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation

        var bulletList = [NSMutableAttributedString]()
        for string in stringList {
            let formattedString = "\(bullet)\t\(string)"
            let attributedString = NSMutableAttributedString(string: formattedString)

            attributedString.addAttributes(
                [NSAttributedString.Key.paragraphStyle: paragraphStyle],
                range: NSMakeRange(0, attributedString.length))

            attributedString.addAttributes(
                textAttributes,
                range: NSMakeRange(0, attributedString.length))

            let string: NSString = NSString(string: formattedString)
            let rangeForBullet: NSRange = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            bulletList.append(attributedString)
        }

        return bulletList
    }
}

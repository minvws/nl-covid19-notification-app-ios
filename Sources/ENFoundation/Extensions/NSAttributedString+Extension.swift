/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

public extension NSAttributedString {

    static func make(text: String, font: UIFont, textColor: UIColor = .black, textAlignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil, underlineColor: UIColor? = nil, letterSpacing: CGFloat? = nil) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment

        if let lineHeight = lineHeight {
            paragraphStyle.lineSpacing = lineHeight
        }

        var attributes: [Key: Any] = [
            .foregroundColor: textColor,
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        if let underlineColor = underlineColor {
            attributes[.underlineColor] = underlineColor
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        if let letterSpacing = letterSpacing {
            attributes[.kern] = letterSpacing
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
        let data: Data = text.data(using: .unicode) ?? Data(text.utf8)

        if let attributedTitle = try? NSMutableAttributedString(data: data,
                                                                options: [.documentType: NSAttributedString.DocumentType.html],
                                                                documentAttributes: nil) {

            let fullRange = NSRange(location: 0, length: attributedTitle.length)
            attributedTitle.addAttributes(attributes, range: fullRange)

            let boldFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)
            let boldFont = boldFontDescriptor.map { UIFont(descriptor: $0, size: font.pointSize) }

            let italicFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic)
            let italicFont = italicFontDescriptor.map { UIFont(descriptor: $0, size: font.pointSize) }

            // replace default font with desired font - maintain bold style if possible
            attributedTitle.enumerateAttribute(.font, in: fullRange, options: []) { value, range, finished in
                guard let currentFont = value as? UIFont else { return }

                var newFont = currentFont

                if let italicFont = italicFont, currentFont.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                    newFont = italicFont
                }

                if let boldFont = boldFont, currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    newFont = boldFont
                }

                attributedTitle.removeAttribute(.font, range: range)
                attributedTitle.addAttribute(.font, value: newFont, range: range)
            }

            return attributedTitle
        }

        return NSAttributedString(string: text)
    }

    static func htmlWithBulletList(text: String, font: UIFont, textColor: UIColor, theme: Theme, textAlignment: NSTextAlignment) -> NSAttributedString {

        let inputString = text.replacingOccurrences(of: "\n\n", with: "<br /><br />")

        guard containsHtml(inputString) else {
            return NSMutableAttributedString(attributedString: make(text: inputString, font: font, textColor: textColor, textAlignment: textAlignment))
        }

        let textToFormat = NSMutableAttributedString(attributedString: makeFromHtml(text: inputString, font: font, textColor: textColor, textAlignment: textAlignment))

        let bullet = "\t•\t"

        guard textToFormat.string.contains(bullet) else {
            return textToFormat
        }

        // Replace all lines starting with bullets with our own custom-formatted bulleted line
        textToFormat.string
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix(bullet) }
            .forEach { line in
                if let lineRange = textToFormat.string.range(of: line) {
                    let attributedLine = makeBullet(line.replacingOccurrences(of: bullet, with: ""), theme: theme, font: font, useTrailingNewLine: false, textAlignment: textAlignment)
                    textToFormat.replaceCharacters(in: NSRange(lineRange, in: line), with: attributedLine)
                }
            }

        return textToFormat
    }

    static func makeBullet(_ string: String,
                           theme: Theme,
                           font: UIFont,
                           useTrailingNewLine: Bool,
                           bullet: String = "\u{25CF}",
                           indentation: CGFloat = 16,
                           paragraphSpacing: CGFloat = 12,
                           textAlignment: NSTextAlignment = .left) -> NSAttributedString {

        let textAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: theme.colors.gray]

        let bulletFont = font.withSize(10)
        let bulletAttributes: [NSAttributedString.Key: Any] = [
            .font: bulletFont,
            .foregroundColor: theme.colors.primary,
            .baselineOffset: (font.xHeight - bulletFont.xHeight) / 2
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        let nonOptions = [NSTextTab.OptionKey: Any]()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: textAlignment, location: indentation, options: nonOptions)
        ]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        paragraphStyle.alignment = textAlignment

        var formattedString = "\(bullet)\t\(string)"

        if useTrailingNewLine {
            formattedString += "\n"
        }

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

        return attributedString
    }

    static func bulletList(_ stringList: [String],
                           theme: Theme,
                           font: UIFont,
                           useTrailingNewLine: Bool,
                           bullet: String = "\u{25CF}",
                           indentation: CGFloat = 16,
                           paragraphSpacing: CGFloat = 12) -> [NSAttributedString] {

        let bulletList = stringList.map {
            makeBullet($0,
                       theme: theme,
                       font: font,
                       useTrailingNewLine: useTrailingNewLine)
        }

        return bulletList
    }

    private static func containsHtml(_ value: String) -> Bool {
        let range = NSRange(location: 0, length: value.utf16.count)
        let regex = try! NSRegularExpression(pattern: "<[^>]+>")
        return regex.firstMatch(in: value, options: [], range: range) != nil
    }
}

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

            // replace default font with desired font - maintain bold style if possible
            attributedTitle.enumerateAttribute(.font, in: fullRange, options: []) { value, range, finished in
                guard let currentFont = value as? UIFont else { return }

                let newFont: UIFont

                if let boldFont = boldFont, currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
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

    static func htmlWithBulletList(text: String, font: UIFont, textColor: UIColor, theme: Theme, textAlignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil, underlineColor: UIColor? = nil) -> NSAttributedString {

        var textToFormat = makeFromHtml(text: text, font: font, textColor: textColor)

        if !containsHtml(text) {
            textToFormat = make(text: text, font: font, textColor: textColor)
        }

        guard textToFormat.string.contains("\t•\t") else {
            return textToFormat
        }

        var bulletList = [NSAttributedString]()

        let bulletPoints = textToFormat.string
            .components(separatedBy: "\t•\t")
            .filter { $0.count > 0 }

        for bulletPoint in bulletPoints {

            let newLineComponents = bulletPoint.components(separatedBy: "\n").filter { !$0.isEmpty }

            for (index, newLine) in newLineComponents.enumerated() {

                let useTrailingNewLine = (index != newLineComponents.count - 1) || bulletPoint != bulletPoints.last

                if index == 0 {
                    bulletList.append(makeBullet(newLine, theme: theme, font: font, useTrailingNewLine: useTrailingNewLine))
                } else {
                    // if a bulletpoint contains a new line, we treat that 2nd line as a separate paragraph that is not
                    // part of the bulletpoint itself and has no indentation.
                    bulletList.append(make(text: newLine, font: font, textColor: theme.colors.gray))
                }
            }
        }

        if !bulletList.isEmpty {
            let list = NSMutableAttributedString()
            bulletList.forEach {
                list.append($0)
            }
            textToFormat = list
        }

        return textToFormat
    }

    static func makeBullet(_ string: String,
                           theme: Theme,
                           font: UIFont,
                           useTrailingNewLine: Bool,
                           bullet: String = "\u{25CF}",
                           indentation: CGFloat = 16,
                           paragraphSpacing: CGFloat = 12) -> NSAttributedString {

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
            NSTextTab(textAlignment: .left, location: indentation, options: nonOptions)
        ]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation

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

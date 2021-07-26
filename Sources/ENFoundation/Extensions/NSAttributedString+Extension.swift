/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

public extension NSAttributedString {

    enum AccessibilityTextCustomValue: String {
        case accessibilityListIndex = "index"
        case accessibilityListSize = "count"
    }

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
            attributedTitle.replaceBoldAndItalicAttributes(font: font)

            return attributedTitle
        }

        return NSAttributedString(string: text)
    }

    func split(_ separatedBy: String) -> [NSAttributedString] {
        var output = [NSAttributedString]()

        let parts = string.components(separatedBy: separatedBy)

        var start = 0
        for part in parts {
            let range = NSMakeRange(start, part.utf16.count)
            let attributedString = attributedSubstring(from: range)
            output.append(attributedString)
            start += range.length + separatedBy.utf16.count
        }

        return output
    }

    static func htmlWithBulletList(text: String, font: UIFont, textColor: UIColor, theme: Theme, textAlignment: NSTextAlignment) -> [NSAttributedString] {

        let inputString = text
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\n\n", with: "<br /><br />")

        guard containsHtml(inputString) else {
            return [NSMutableAttributedString(attributedString: make(text: inputString, font: font, textColor: textColor, textAlignment: textAlignment))]
        }

        let textToFormat = NSMutableAttributedString(attributedString: makeFromHtml(text: inputString, font: font, textColor: textColor, textAlignment: textAlignment))

        let bullet = "\t•\t"

        guard textToFormat.string.contains(bullet) else {
            return [textToFormat]
        }

        // Find all lines starting with bullets
        let bullets = textToFormat.string
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix(bullet) }

        // Replace all with our own custom-formatted bulleted line
        bullets.enumerated().forEach { index, line in
            guard let lineRange = textToFormat.string.range(of: line) else {
                return
            }
            let range = NSRange(lineRange, in: line)
            let attributedLine = NSMutableAttributedString(attributedString: textToFormat.attributedSubstring(from: range))
            attributedLine.reformatBulletPoint(font: font, theme: theme, textAlignment: textAlignment)
            attributedLine.addAttribute(.accessibilityTextCustom, value: [
                AccessibilityTextCustomValue.accessibilityListIndex.rawValue: index,
                AccessibilityTextCustomValue.accessibilityListSize.rawValue: bullets.count
            ], range: NSRange(location: 0, length: attributedLine.length))
            textToFormat.replaceCharacters(in: range, with: attributedLine)
        }

        return textToFormat
            .attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines)
            .split("\n")
    }

    static func makeBullet(_ string: String,
                           theme: Theme,
                           font: UIFont,
                           bullet: String = "\u{25CF}",
                           indentation: CGFloat = 16,
                           paragraphSpacing: CGFloat = 12,
                           textAlignment: NSTextAlignment = .left) -> NSMutableAttributedString {

        let textAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: theme.colors.textSecondary]

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

        return attributedString
    }

    static func bulletList(_ stringList: [String],
                           theme: Theme,
                           font: UIFont,
                           bullet: String = "\u{25CF}",
                           indentation: CGFloat = 16,
                           paragraphSpacing: CGFloat = 12,
                           textAlignment: NSTextAlignment = .left) -> [NSAttributedString] {

        let bullets = stringList.map {
            makeBullet($0,
                       theme: theme,
                       font: font,
                       bullet: bullet,
                       indentation: indentation,
                       paragraphSpacing: paragraphSpacing,
                       textAlignment: textAlignment
            )
        }

        return bullets.enumerated().map { index, bullet in
            bullet.addAttribute(.accessibilityTextCustom, value: [
                AccessibilityTextCustomValue.accessibilityListIndex.rawValue: index,
                AccessibilityTextCustomValue.accessibilityListSize.rawValue: bullets.count
            ], range: NSRange(location: 0, length: bullet.string.count))
            return bullet
        }
    }

    private static func containsHtml(_ value: String) -> Bool {
        let range = NSRange(location: 0, length: value.utf16.count)
        let regex = try! NSRegularExpression(pattern: "<[^>]+>")
        return regex.firstMatch(in: value, options: [], range: range) != nil
    }

    func attributedStringByTrimmingCharacterSet(charSet: CharacterSet) -> NSAttributedString {
        let modifiedString = NSMutableAttributedString(attributedString: self)
        modifiedString.trimCharactersInSet(charSet: charSet)
        return NSAttributedString(attributedString: modifiedString)
    }
}

extension NSMutableAttributedString {
    func trimCharactersInSet(charSet: CharacterSet) {
        var range = (string as NSString).rangeOfCharacter(from: charSet as CharacterSet)

        // Trim leading characters from character set.
        while range.length != 0, range.location == 0 {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet)
        }

        // Trim trailing characters from character set.
        range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        while range.length != 0, NSMaxRange(range) == length {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        }
    }

    func replaceBoldAndItalicAttributes(font: UIFont) {

        let fullRange = NSRange(location: 0, length: length)

        let boldFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)
        let boldFont = boldFontDescriptor.map { UIFont(descriptor: $0, size: font.pointSize) }

        let italicFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic)
        let italicFont = italicFontDescriptor.map { UIFont(descriptor: $0, size: font.pointSize) }

        // replace default font with desired font - maintain bold style if possible
        self.enumerateAttribute(.font, in: fullRange, options: []) { value, range, finished in
            guard let currentFont = value as? UIFont else { return }

            var newFont = font

            if let italicFont = italicFont, currentFont.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                newFont = italicFont
            }

            if let boldFont = boldFont, currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
                newFont = boldFont
            }

            self.removeAttribute(.font, range: range)
            self.addAttribute(.font, value: newFont, range: range)
        }
    }

    func reformatBulletPoint(font: UIFont, theme: Theme, textAlignment: NSTextAlignment) {

        let bullet = "\t•\t"

        if let bulletRange = self.string.range(of: bullet) {

            let bulletFont = font.withSize(10)
            let bulletAttributes: [NSAttributedString.Key: Any] = [
                .font: bulletFont,
                .foregroundColor: theme.colors.primary,
                .baselineOffset: (font.xHeight - bulletFont.xHeight) / 2
            ]
            let newBullet = NSMutableAttributedString(string: "\u{25CF}\t", attributes: bulletAttributes)
            self.replaceCharacters(in: NSRange(bulletRange, in: self.string), with: newBullet)
        }

        let paragraphStyle = NSMutableParagraphStyle()
        let nonOptions = [NSTextTab.OptionKey: Any]()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: textAlignment, location: 16, options: nonOptions)
        ]
        paragraphStyle.defaultTabInterval = 16
        paragraphStyle.headIndent = 16
        paragraphStyle.alignment = textAlignment
        paragraphStyle.paragraphSpacing = 5

        self.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSMakeRange(0, self.length))
    }

    public func centered() -> NSMutableAttributedString {

        let copiedString = NSMutableAttributedString(attributedString: self)

        let fullRange = NSRange(location: 0, length: copiedString.length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        copiedString.addAttributes([.paragraphStyle: paragraphStyle], range: fullRange)

        return copiedString
    }
}

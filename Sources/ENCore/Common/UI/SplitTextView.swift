/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// Styled subclass of UIStackView that displays one or more TextElement's, which can handle (simple) html
/// Auto expands to fit its content.
/// By default the content is not editable or selectable.
/// Can listen to selected links and updated text.
class SplitTextView: UIStackView {

    private let theme: Theme
    private let paragraphMargin: CGFloat = 14
    private let headerMargin: CGFloat = 24
    private let listItemMargin: CGFloat = 6

    /// Helper variable to display the given text by using a TextElement
    var text: String? {
        didSet {
            removeAllArrangedSubviews()

            let element = SplitTextElement(theme: theme, text: text)
            addArrangedSubview(element)
        }
    }

    /// Helper variable to display a TextElement for each paragraph in the attributed string
    var attributedText: NSAttributedString? {
        didSet {
            removeAllArrangedSubviews()

            guard let attributedText = attributedText else { return }

            // Split attributed text on new line
            let parts = attributedText.split("\n").filter { !$0.string.isEmpty }

            for part in parts {
                // 1. Determine spacing of previous element
                if let previousElement = arrangedSubviews.last {
                    let spacing: CGFloat

                    if part.isHeader {
                        spacing = headerMargin
                    } else if part.isListItem {
                        spacing = listItemMargin
                    } else {
                        spacing = paragraphMargin
                    }

                    setCustomSpacing(spacing, after: previousElement)
                }

                // 2. Add current SplitTextElement
                let element = SplitTextElement(theme: theme, attributedText: part, font: theme.fonts.body, textColor: theme.colors.textDark, boldTextColor: theme.colors.textDark)
                if part.isHeader {
                    element.accessibilityTraits = .header
                }
                addArrangedSubview(element)
            }
        }
    }

    /// Helper variable to retrieve all subviews
    var textElements: [SplitTextElement] {
        return arrangedSubviews.compactMap { view in
            return view as? SplitTextElement
        }
    }

    /// Helper variable to pass linkTextAttributes to each subview
    var linkTextAttributes: [NSAttributedString.Key: Any]? {
        didSet {
            textElements.forEach { $0.linkTextAttributes = linkTextAttributes }
        }
    }

    /// Initializes the TextView by parsing the given string to HTML
    init(
        theme: Theme,
        htmlText: String,
        font: UIFont,
        textColor: UIColor,
        boldTextColor: UIColor
    ) {

        self.theme = theme
        super.init(frame: .zero)
        setup()

        html(htmlText, font: font, textColor: textColor, boldTextColor: boldTextColor)
    }

    //// Initializes the TextView with a string
    init(theme: Theme, text: String? = nil) {
        self.theme = theme
        super.init(frame: .zero)
        setup()

        self.text = text
    }

    /// Initializes the TextView with an attributed string
    init(theme: Theme, attributedText: NSAttributedString) {
        self.theme = theme
        super.init(frame: .zero)
        setup()

        self.attributedText = attributedText
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set vertical alignment
    private func setup() {
        axis = .vertical
    }

    /// Sets the content to the supplied html string.
    @discardableResult
    func html(_ htmlText: String, font: UIFont, textColor: UIColor, boldTextColor: UIColor) -> Self {
        attributedText = .makeFromHtml(text: htmlText, font: font, textColor: textColor, textAlignment: Localization.textAlignment)
        return self
    }

    /// Add a listener for selected links. Calling this method will set `isSelectable` to `true`
    ///
    /// - parameter handler: The closure to be called when the user selects a link
    @discardableResult
    func linkTouched(handler: @escaping (URL) -> ()) -> Self {
        textElements.forEach { $0.linkTouched(handler: handler) }
        return self
    }

    /// Add a listener for updated text. Calling this method will set `isSelectable` and `isEditable` to `true`
    ///
    /// - parameter handler: The closure to be called when the text is updated
    @discardableResult
    func textChanged(handler: @escaping (String?) -> ()) -> Self {
        textElements.forEach { $0.textChanged(handler: handler) }
        return self
    }

    /// Removes all arranged subviews
    @discardableResult
    func removeAllArrangedSubviews() -> [UIView] {
        let removedSubviews = arrangedSubviews.reduce([]) { removedSubviews, subview -> [UIView] in
            self.removeArrangedSubview(subview)
            NSLayoutConstraint.deactivate(subview.constraints)
            subview.removeFromSuperview()
            return removedSubviews + [subview]
        }
        return removedSubviews
    }
}

extension NSAttributedString {

    /// Helper method to split an attributed string by using the given separator
    func split(_ separator: String) -> [NSAttributedString] {
        var substrings = [NSAttributedString]()

        var index = 0
        for component in self.string.components(separatedBy: separator) {
            let range = NSRange(location: index, length: component.utf16.count)

            let substring = self.attributedSubstring(from: range)
            substrings.append(substring)

            index += range.length + separator.count
        }

        return substrings
    }

    /// Helper method to find certain attributes of an attributed string
    func attributes(find: (_ key: Key, _ value: Any, _ range: NSRange) -> (Bool)) -> Bool {
        var result = false
        enumerateAttributes(in: NSRange(location: 0, length: self.length)) { attributes, range, stop in
            for (key, value) in attributes {
                if find(key, value, range) {
                    result = true
                    break
                }
            }
        }
        return result
    }

    /// Determines whether the attributed string is a header
    var isHeader: Bool {
        return attributes { key, value, range in

            // Check if full range uses a bold font
            if key == NSAttributedString.Key.font,
                let font = value as? UIFont,
                font.fontDescriptor.symbolicTraits.contains(.traitBold),
                range.lowerBound == 0,
                range.upperBound >= self.length - 1 {
                return true
            }

            return false
        }
    }

    // swiftlint:disable empty_count
    /// Determines whether the attributed string is a list item
    var isListItem: Bool {
        // Check if strings starts with tabbed bullet character
        if string.starts(with: "\t●") || string.starts(with: "\t•") || string.starts(with: "●\t") {
            return true
        }

        // Check if textLists attribute contains one or more elements
        return attributes { key, value, _ in

            if key == NSAttributedString.Key.paragraphStyle,
                let paragraphStyle = value as? NSParagraphStyle,
                paragraphStyle.textLists.count > 0 {
                return true
            }
            return false
        }
    }

    /// Determines the line height used for the attributed string
    var lineHeight: CGFloat {
        var height: CGFloat = 0

        // Retrieve the maximum value set for minimumLineHeight in NSParagraphStyle
        enumerateAttributes(in: NSRange(location: 0, length: self.length)) { attributes, range, stop in
            for (key, value) in attributes {
                if key == NSAttributedString.Key.paragraphStyle,
                    let paragraphStyle = value as? NSParagraphStyle,
                    paragraphStyle.minimumLineHeight > height {
                    height = paragraphStyle.minimumLineHeight
                }
            }
        }

        return height
    }
}

extension NSParagraphStyle {

    var headerLevel: Int {
        let key = "headerLevel"
        if responds(to: NSSelectorFromString(key)) {
            return value(forKey: key) as? Int ?? 0
        }
        return 0
    }

    var textLists: NSArray {
        let key = "textLists"
        if responds(to: NSSelectorFromString(key)) {
            return value(forKey: key) as? NSArray ?? []
        }
        return []
    }
}

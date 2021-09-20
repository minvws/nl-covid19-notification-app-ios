/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// Styled subclass of UITextView that can handle (simple) html.
/// Auto expands to fit its content.
/// By default the content is not editable or selectable.
/// Can listen to selected links and updated text.
class SplitTextElement: UITextView, UITextViewDelegate {

    private var linkHandlers = [(URL) -> ()]()
    private var textChangedHandlers = [(String?) -> ()]()
    private let theme: Theme

    ///  Initializes the TextView with the given attributed string
    init(
        theme: Theme,
        attributedText: NSAttributedString,
        font: UIFont,
        textColor: UIColor,
        boldTextColor: UIColor
    ) {
        self.theme = theme
        super.init(frame: .zero, textContainer: nil)
        setup()

        self.attributedText = attributedText
    }

    ///  Initializes the TextView with the given string
    init(theme: Theme, text: String? = nil) {
        self.theme = theme
        super.init(frame: .zero, textContainer: nil)
        setup()

        self.text = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Sets up the TextElement with the default settings
    private func setup() {
        isAccessibilityElement = true
        delegate = self

        font = theme.fonts.body
        isScrollEnabled = false
        isEditable = false
        isSelectable = false
        backgroundColor = nil
        layer.cornerRadius = 0
        textContainer.lineFragmentPadding = 0
        textContainerInset = .zero
        linkTextAttributes = [
            .foregroundColor: theme.colors.primary,
            .underlineColor: theme.colors.primary
        ]
    }

    /// Calculates the intrisic content size
    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize

        if isEditable {
            return CGSize(width: 200, height: max(114, superSize.height))
        } else {
            return superSize
        }
    }

    /// Add a listener for selected links. Calling this method will set `isSelectable` to `true`
    ///
    /// - parameter handler: The closure to be called when the user selects a link
    @discardableResult
    func linkTouched(handler: @escaping (URL) -> ()) -> Self {
        isSelectable = true
        linkHandlers.append(handler)
        return self
    }

    /// Add a listener for updated text. Calling this method will set `isSelectable` and `isEditable` to `true`
    ///
    /// - parameter handler: The closure to be called when the text is updated
    @discardableResult
    func textChanged(handler: @escaping (String?) -> ()) -> Self {
        isSelectable = true
        isEditable = true
        textChangedHandlers.append(handler)
        return self
    }

    /// Delegate method to determine whether a URL can be interacted with
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            linkHandlers.forEach { $0(URL) }
        default:
            return false
        }

        return false
    }

    /// Delegate method which is called when the user has ended editing
    func textViewDidEndEditing(_ textView: UITextView) {
        textChangedHandlers.forEach { $0(textView.text) }
    }

    /// Delegate method which is called when the user has changed selection
    func textViewDidChangeSelection(_ textView: UITextView) {
        // Allows links to be tapped but disables text selection
        textView.selectedTextRange = nil
    }
}

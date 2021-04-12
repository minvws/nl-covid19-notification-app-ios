/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

class Label: UILabel {

    private var charactersToRemove: String?

    /// Indicates that the text in this label can or can not be copied by using the long press gesture
    /// - Parameters:
    ///   - canBeCopied: Enable or disable copying
    ///   - characters: Characters in this string will be removed from the contents of the label when it is copied
    func textCanBeCopied(_ canBeCopied: Bool = true, charactersToRemove: String? = nil) {
        super.awakeFromNib()

        self.charactersToRemove = charactersToRemove

        isUserInteractionEnabled = canBeCopied

        if canBeCopied == false {
            removeGestureRecognizer(longPressGestureRecognizer)
            return
        }

        addGestureRecognizer(longPressGestureRecognizer)
    }

    override var attributedText: NSAttributedString? {
        get {
            return super.attributedText
        }
        set {
            super.attributedText = newValue

            guard let newText = newValue, newText.length > 0 else {
                return
            }

            let attributes = newText.attributes(at: 0, effectiveRange: nil)

            guard let accessibilityTextCustom = attributes.filter({ (attribute) -> Bool in
                attribute.key == .accessibilityTextCustom
            }).first else {
                return
            }

            guard let data = accessibilityTextCustom.value as? [String: Int] else {
                return
            }

            guard let index = data[NSAttributedString.AccessibilityTextCustomValue.accessibilityListIndex.rawValue],
                let total = data[NSAttributedString.AccessibilityTextCustomValue.accessibilityListSize.rawValue] else {
                return
            }

            if total > 1 {
                if index == 0 {
                    accessibilityHint = .accessibilityStartOfList
                } else if index == total - 1 {
                    accessibilityHint = .accessibilityEndOfList
                }
            }
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    override func copy(_ sender: Any?) {
        var copiedText = text
        if let charactersToRemove = charactersToRemove {
            copiedText = copiedText?.removingCharacters(from: charactersToRemove)
        }

        UIPasteboard.general.string = copiedText
    }

    @objc private func handleLongPress(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == .began,
            let recognizerView = recognizer.view,
            let recognizerSuperview = recognizerView.superview {
            recognizerView.becomeFirstResponder()

            if #available(iOS 13.0, *) {
                UIMenuController.shared.showMenu(from: recognizerSuperview, rect: recognizerView.frame)
            } else {
                UIMenuController.shared.setTargetRect(recognizerView.frame, in: recognizerSuperview)
                UIMenuController.shared.setMenuVisible(true, animated: true)
            }
        }
    }

    private lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        return gesture
    }()
}

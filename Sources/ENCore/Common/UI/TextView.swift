/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class TextView: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }

    private func setup() {
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }
    
    override var attributedText: NSAttributedString? {
        get {
            return super.attributedText
        }
        set {
            super.attributedText = newValue
            
            updateListAccessibilityHint()
        }
    }
    
    // Point detection on this textview is overridden to only allow touch on links, not on normal text
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return linkExists(atPoint: point)
    }

    private func linkExists(atPoint point: CGPoint) -> Bool {
        guard let attributedText = attributedText else {
            return false
        }
        
        guard let pos = closestPosition(to: point),
            let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .storage(.backward)) else {
            return false
        }

        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
    
    /// Adds a start of list / end of list accessibility hint to this TextView if the attributedtext contains a  custom accessibility text attributes
    private func updateListAccessibilityHint() {
        guard let attributedText = self.attributedText, attributedText.length > 0 else {
            return
        }
        
        let attributes = attributedText.attributes(at: 0, effectiveRange: nil)

        guard let accessibilityTextCustom = attributes.filter({ (attribute) -> Bool in
            attribute.key == .accessibilityTextCustom
        }).first else {
            return
        }

        guard let data = accessibilityTextCustom.value as? [String: Int],
              let index = data[NSAttributedString.AccessibilityTextCustomValue.accessibilityListIndex.rawValue],
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

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

    func setup() {
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }

    // Point detection on this textview is overridden to only allow touch on links, not on normal text
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return linkExists(atPoint: point)
    }

    private func linkExists(atPoint point: CGPoint) -> Bool {
        guard let pos = closestPosition(to: point),
            let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .storage(.backward)) else {
            return false
        }

        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}

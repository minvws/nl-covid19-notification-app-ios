/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class Label: UILabel {

    func textCanBeCopied(_ canBeCopied: Bool = true) {
        super.awakeFromNib()

        isUserInteractionEnabled = canBeCopied

        if !canBeCopied {

            guard let availableGestureRecognizers = gestureRecognizers else {
                return
            }

            for (index, gestureRecognizer) in availableGestureRecognizers.enumerated() {
                if let _ = gestureRecognizer as? UILongPressGestureRecognizer {
                    gestureRecognizers?.remove(at: index)
                }
            }
            return
        }

        addGestureRecognizer(
            UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPress(_:))
            )
        )
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    // MARK: - UIResponderStandardEditActions

    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = text
    }

    @objc private func handleLongPress(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == .began,
            let recognizerView = recognizer.view,
            let recognizerSuperview = recognizerView.superview {
            recognizerView.becomeFirstResponder()
            UIMenuController.shared.showMenu(from: recognizerSuperview, rect: recognizerView.frame)
        }
    }
}

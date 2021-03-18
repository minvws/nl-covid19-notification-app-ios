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

            updateLinkInteraction()
            
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

    private func updateLinkInteraction() {
        let hasLinks = hasLinksInText
        
        isUserInteractionEnabled = hasLinks

        if hasLinks {
            addGestureRecognizer(linkTapGestureRecognizer)
        } else {
            removeGestureRecognizer(linkTapGestureRecognizer)
        }
    }
        
    private var hasLinksInText: Bool {
        guard let text = attributedText?.string else {
            return false
        }
        
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let foundLinks = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return !foundLinks.isEmpty
    }

    private lazy var linkTapGestureRecognizer: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleLinkTap(_:)))
        return gesture
    }()

    @objc private func handleLinkTap(_ recognizer: UIGestureRecognizer) {
        guard recognizer.state == .ended else {
            return
        }

        guard let text = attributedText?.string else {
            return
        }

        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let foundLinks = detector.matches(in: text,
                                          options: [],
                                          range: NSRange(location: 0,
                                                         length: text.utf16.count))

        for link in foundLinks {
            guard let range = Range(link.range, in: text) else { continue }
            if didFoundLinkInLabel(self,
                                   atRange: link.range,
                                   withRecognizer: recognizer) {
                openLinkInExternalBrowser(String(text[range]))
                return
            }
        }
    }

    private func didFoundLinkInLabel(_ label: UILabel, atRange targetRange: NSRange, withRecognizer recognizer: UIGestureRecognizer) -> Bool {
        guard let attributedText = label.attributedText else {
            return false
        }

        let string = attributedText.string

        guard !string.isEmpty else {
            return false
        }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: attributedText)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        let locationOfTouchInLabel = recognizer.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        var indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                            in: textContainer,
                                                            fractionOfDistanceBetweenInsertionPoints: nil)

        var lineBreakCounts = 0
        lineBreakCounts += string.components(separatedBy: "\n").count
        indexOfCharacter += lineBreakCounts

        return NSLocationInRange(indexOfCharacter, targetRange)
    }

    private func openLinkInExternalBrowser(_ link: String) {
        var linkToOpen = link
        if !linkToOpen.starts(with: "https://") {
            linkToOpen = "https://" + link
        }
        guard let url = URL(string: linkToOpen) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

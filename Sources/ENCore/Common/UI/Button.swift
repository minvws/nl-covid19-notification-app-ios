/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

class Button: UIButton, Themeable {

    enum ButtonType {
        case primary
        case secondary
        case secondaryLight
        case tertiary
        case warning
        case info
    }

    var style = ButtonType.primary {
        didSet {
            updateButtonType()
        }
    }

    var rounded = false {
        didSet {
            updateRoundedCorners()
        }
    }

    var title = "" {
        didSet {
            self.setTitle(title, for: .normal)
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateButtonType()
        }
    }

    let theme: Theme
    var action: (() -> ())?
    var useHapticFeedback = true

    // MARK: - Init

    required init(title: String = "", theme: Theme) {
        self.theme = theme
        super.init(frame: .zero)

        self.setTitle(title, for: .normal)
        self.titleLabel?.font = theme.fonts.headline

        self.layer.cornerRadius = 10
        self.clipsToBounds = true

        self.addTarget(self, action: #selector(self.touchUpAnimation), for: .touchDragExit)
        self.addTarget(self, action: #selector(self.touchUpAnimation), for: .touchCancel)
        self.addTarget(self, action: #selector(self.touchUpAnimation), for: .touchUpInside)
        self.addTarget(self, action: #selector(self.touchDownAnimation), for: .touchDown)
        self.addTarget(self, action: #selector(self.touchUpAction), for: .touchUpInside)

        updateButtonType()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        updateRoundedCorners()
    }

    // MARK: - Private

    private func updateButtonType() {
        switch style {
        case .primary:
            if isEnabled {
                backgroundColor = theme.colors.primaryButton
                setTitleColor(.white, for: .normal)
            } else {
                backgroundColor = theme.colors.tertiary
                setTitleColor(theme.colors.textButtonTertiary, for: .normal)
            }
        case .secondary:
            backgroundColor = theme.colors.tertiary
            setTitleColor(theme.colors.textButtonPrimary, for: .normal)
        case .secondaryLight:
            backgroundColor = theme.colors.secondaryLight
            setTitleColor(theme.colors.textButtonPrimary, for: .normal)
        case .tertiary:
            backgroundColor = theme.colors.tertiary
            setTitleColor(theme.colors.textPrimary, for: .normal)
        case .warning:
            backgroundColor = theme.colors.warning
            setTitleColor(.white, for: .normal)
        case .info:
            backgroundColor = .clear
            setTitleColor(theme.colors.primary, for: .normal)
        }

        tintColor = .white
    }

    private func updateRoundedCorners() {
        if rounded {
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }
    }

    @objc private func touchDownAnimation() {

        if useHapticFeedback { Haptic.light() }

        UIButton.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        })
    }

    @objc private func touchUpAnimation() {
        UIButton.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform.identity
        })
    }

    @objc private func touchUpAction() {
        action?()
    }
}

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
            setTitle(title, for: .normal)
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

    required init(title: String = "", theme: Theme, icon: UIImage? = nil) {
        self.theme = theme
        super.init(frame: .zero)

        setTitle(title, for: .normal)
        titleLabel?.font = theme.fonts.headline
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center

        if let icon = icon {
            transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            setImage(icon.resizedTo(CGSize(width: 30, height: 30)), for: .normal)
            imageView?.contentMode = .scaleAspectFit
            imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            imageEdgeInsets = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 15)
        }

        layer.cornerRadius = 10
        clipsToBounds = true

        addTarget(self, action: #selector(touchUpAnimation), for: .touchDragExit)
        addTarget(self, action: #selector(touchUpAnimation), for: .touchCancel)
        addTarget(self, action: #selector(touchUpAnimation), for: .touchUpInside)
        addTarget(self, action: #selector(touchDownAnimation), for: .touchDown)
        addTarget(self, action: #selector(touchUpAction), for: .touchUpInside)

        if let label = titleLabel {
            label.snp.makeConstraints { maker in
                maker.top.greaterThanOrEqualToSuperview()
                maker.bottom.lessThanOrEqualToSuperview()
            }
        }

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
            setTitleColor(theme.colors.textButtonSecondaryLight, for: .normal)
        case .tertiary:
            backgroundColor = theme.colors.tertiary
            setTitleColor(theme.colors.textPrimary, for: .normal)
        case .warning:
            backgroundColor = theme.colors.warningButton
            setTitleColor(.white, for: .normal)
        case .info:
            backgroundColor = .clear
            setTitleColor(theme.colors.primary, for: .normal)
        }

        tintColor = .white
    }

    /// Overridden to show black border on keyboard focus
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if isFocused {
            layer.borderWidth = 5
            layer.borderColor = theme.colors.focusBorder.cgColor
        } else {
            layer.borderWidth = 0
        }
    }

    private func updateRoundedCorners() {
        if rounded {
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }
    }

    @objc private func touchDownAnimation() {
        if useHapticFeedback { Haptic.light() }

        UIButton.animate(withDuration: 0.2, animations: {
            guard self.imageView?.image == nil else { return }
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        })
    }

    @objc private func touchUpAnimation() {
        UIButton.animate(withDuration: 0.2, animations: {
            guard self.imageView?.image == nil else { return }
            self.transform = CGAffineTransform.identity
        })
    }

    @objc private func touchUpAction() {
        action?()
    }
}

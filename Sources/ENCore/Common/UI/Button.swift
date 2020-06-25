/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class Button: UIButton, Themeable {

    enum ButtonType {
        case primary, secondary, tertiary
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
        self.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)

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
                backgroundColor = theme.colors.primary
                setTitleColor(.white, for: .normal)
            } else {
                backgroundColor = theme.colors.tertiary
                setTitleColor(.gray, for: .normal)
            }
        case .secondary:
            self.backgroundColor = theme.colors.secondary
            self.setTitleColor(.white, for: .normal)
        case .tertiary:
            self.backgroundColor = theme.colors.tertiary
            self.setTitleColor(theme.colors.primary, for: .normal)
        }

        self.tintColor = .white
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

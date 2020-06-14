/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

class Button: UIButton {

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

    var action: (() -> Void)?

    var useHapticFeedback = true

    required init(title: String = "") {

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

    override func layoutSubviews() {
        super.layoutSubviews()
        updateRoundedCorners()
    }

    fileprivate func updateButtonType() {
        switch style {
        case .primary:
            self.backgroundColor = .primaryColor
            self.setTitleColor(.white, for: .normal)
        case .secondary:
            self.backgroundColor = .secondaryColor
            self.setTitleColor(.white, for: .normal)
        case .tertiary:
            self.backgroundColor = .tertiaryColor
            self.setTitleColor(.primaryColor, for: .normal)
        }

        self.tintColor = .white
    }

    fileprivate func updateRoundedCorners() {
        if rounded {
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }
    }

    @objc func touchDownAnimation() {

        if useHapticFeedback { Haptic.light() }

        UIButton.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        })
    }

    @objc func touchUpAnimation() {
        UIButton.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform.identity
        })
    }

    @objc func touchUpAction() {
        action?()
    }

}


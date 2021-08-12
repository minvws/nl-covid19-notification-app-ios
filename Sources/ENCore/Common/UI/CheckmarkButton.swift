/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

final class CheckmarkButton: Button {

    // This switch is only used to give correct accessibility traits and values to this button
    private let shadowSwitch = UISwitch()

    required init(theme: Theme) {
        super.init(theme: theme)
        isSelected = false
        style = .tertiary
        build()
        setupContraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(title: String = "", theme: Theme) {
        fatalError("init(title:theme:) has not been implemented")
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get { shadowSwitch.accessibilityTraits }
        set {}
    }

    override var accessibilityValue: String? {
        get { shadowSwitch.accessibilityValue }
        set {}
    }

    override var isSelected: Bool {
        didSet {
            shadowSwitch.isOn = isSelected
            checkmark.image = isSelected ? .checkmarkChecked : .checkmarkUnchecked
            shadowSwitch.sendActions(for: .valueChanged)
        }
    }

    private func build() {
        addSubview(label)
        addSubview(checkmark)
    }

    private func setupContraints() {
        checkmark.snp.makeConstraints { maker in
            maker.width.height.equalTo(28)
            maker.leading.equalToSuperview().inset(16)
            maker.centerY.equalToSuperview()
        }

        label.snp.makeConstraints { maker in
            maker.leading.equalTo(checkmark.snp.trailing).offset(16)
            maker.trailing.top.bottom.equalToSuperview().inset(16)
        }
    }

    private lazy var checkmark = UIImageView(image: .checkmarkUnchecked)

    lazy var label: Label = {
        let label = Label(frame: .zero)
        label.numberOfLines = 0
        label.textColor = theme.colors.textSecondary
        label.font = theme.fonts.subhead(limitMaximumSize: true)
        return label
    }()
}

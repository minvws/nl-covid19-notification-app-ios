/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import SnapKit
import UIKit

protocol MoreInformationCellListner: AnyObject {
    func didSelect(identifier: MoreInformationIdentifier)
}

final class MoreInformationCell: UIControl, Themeable {

    override var isHighlighted: Bool {
        didSet {
            // TODO: Should actually to proper UITableView touch styling
            UIView.animate(withDuration: 0.25) {
                self.alpha = self.isHighlighted ? 0.6 : 1.0
            }
        }
    }

    let theme: Theme

    // MARK: - Init

    init(listener: MoreInformationCellListner, theme: Theme, data: MoreInformation, borderIsHidden: Bool = false) {
        self.listener = listener
        self.identifier = data.identifier
        self.theme = theme
        self.borderView = View(theme: theme)
        self.chevronImageView = UIImageView(image: .chevron)
        self.iconImageView = UIImageView(frame: .zero)
        self.titleLabel = Label()
        self.subtitleLabel = Label()
        super.init(frame: .zero)

        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.accessibilityLabel = "\(data.title). \(data.subtitle)"

        build()
        setupConstraints()

        iconImageView.image = data.icon
        titleLabel.text = data.title
        subtitleLabel.text = data.subtitle
        borderView.isHidden = borderIsHidden
    }

    @available(*, unavailable, message: "NSCoder and Interface Builder is not supported. Use Programmatic layout.")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private weak var listener: MoreInformationCellListner?
    private let identifier: MoreInformationIdentifier

    private let borderView: View
    private let chevronImageView: UIImageView
    private let iconImageView: UIImageView
    private let titleLabel: Label
    private let subtitleLabel: Label

    @objc private func didTap() {
        Haptic.light()
        listener?.didSelect(identifier: identifier)
    }

    private func build() {

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        borderView.backgroundColor = UIColor(red: 0.933, green: 0.933, blue: 0.933, alpha: 1)

        titleLabel.font = theme.fonts.headline
        subtitleLabel.font = theme.fonts.subhead

        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping

        addSubview(borderView)
        addSubview(chevronImageView)
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }

    private func setupConstraints() {

        iconImageView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.equalToSuperview().offset(16)
            maker.top.equalToSuperview().offset(23)
            maker.width.height.equalTo(40)
        }
        titleLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(16)
            maker.top.equalTo(iconImageView)
            maker.trailing.equalTo(chevronImageView).inset(12)
        }
        subtitleLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.leading.trailing.equalTo(titleLabel)
            maker.bottom.equalToSuperview().inset(20)
        }
        chevronImageView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.trailing.equalToSuperview().inset(16)
            maker.width.equalTo(8)
            maker.height.equalTo(16)
            maker.centerY.equalTo(titleLabel)
        }
        borderView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.equalTo(titleLabel)
            maker.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            maker.trailing.equalToSuperview()
            maker.height.equalTo(1)
        }
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import SnapKit
import UIKit

struct InfoHeaderConfig {
    enum Alignment {
        case top
        case bottom
    }

    let alignment: Alignment
    let backgroundColor: UIColor
    let imageView: UIImage?
}

struct InfoViewConfig {
    let actionButtonTitle: String
    let headerConfig: InfoHeaderConfig
}

final class InfoView: View {

    var actionHandler: (() -> ())?

    private let scrollView: UIScrollView
    private let contentView: UIView

    private let headerView: UIView
    private let headerImageView: UIImageView
    private let stackView: UIStackView
    private let actionButton: Button

    private let headerConfig: InfoHeaderConfig

    // MARK: - Init

    init(theme: Theme, config: InfoViewConfig) {
        self.headerConfig = config.headerConfig
        self.headerView = UIView(frame: .zero)
        self.contentView = UIView(frame: .zero)
        self.headerImageView = UIImageView(image: config.headerConfig.imageView)
        self.stackView = UIStackView(frame: .zero)
        self.scrollView = UIScrollView(frame: .zero)
        self.actionButton = Button(title: config.actionButtonTitle, theme: theme)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        actionButton.addTarget(self, action: #selector(didTapActionButton(sender:)), for: .touchUpInside)

        headerView.backgroundColor = headerConfig.backgroundColor
        headerImageView.contentMode = .scaleAspectFill
        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.distribution = .equalSpacing
        contentView.backgroundColor = .clear

        addSubview(scrollView)
        headerView.addSubview(headerImageView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerView)
        contentView.addSubview(stackView)
        contentView.addSubview(actionButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(scrollView)
            maker.bottom.equalTo(scrollView)
            maker.leading.trailing.equalTo(self)
        }
        headerView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.equalToSuperview()
        }
        headerImageView.snp.makeConstraints { (maker: ConstraintMaker) in
            switch headerConfig.alignment {
            case .top:
                maker.top.equalToSuperview()
            case .bottom:
                maker.top.equalToSuperview().offset(40)
            }
            maker.leading.trailing.bottom.equalToSuperview()
        }
        stackView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(headerView.snp.bottom).offset(24)
            maker.leading.trailing.equalToSuperview()
        }
        actionButton.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.height.equalTo(48)
            maker.top.equalTo(stackView.snp.bottom).offset(16)
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.bottom.equalToSuperview()
        }
    }

    // MARK: - Internal

    func addSections(_ views: [UIView]) {
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }

    // MARK: - Private

    @objc private func didTapActionButton(sender: Button) {
        actionHandler?()
    }
}

final class InfoSectionTextView: View {

    private let titleLabel: Label
    private let contentLabel: Label

    // MARK: - Init

    init(theme: Theme, title: String, content: NSAttributedString) {
        self.titleLabel = Label(frame: .zero)
        self.contentLabel = Label(frame: .zero)
        super.init(theme: theme)

        titleLabel.text = title
        contentLabel.attributedText = content
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title2
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.font = theme.fonts.body

        addSubview(titleLabel)
        addSubview(contentLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
        }
        contentLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(10)
            maker.leading.trailing.equalTo(titleLabel)
            maker.bottom.equalToSuperview()
        }
    }
}

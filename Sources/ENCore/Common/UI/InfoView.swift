/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import SnapKit
import UIKit

struct InfoViewConfig {
    let actionButtonTitle: String
    let headerImage: UIImage?
}

final class InfoView: View {

    var actionHandler: (() -> ())?
    var isActionButtonEnabled: Bool = true {
        didSet { actionButton.isEnabled = isActionButtonEnabled }
    }

    private let scrollView: UIScrollView
    private let contentView: UIView

    private let headerImageView: UIImageView
    private let stackView: UIStackView
    private let actionButton: Button

    // MARK: - Init

    init(theme: Theme, config: InfoViewConfig) {
        self.contentView = UIView(frame: .zero)
        self.headerImageView = UIImageView(image: config.headerImage)
        self.stackView = UIStackView(frame: .zero)
        self.scrollView = UIScrollView(frame: .zero)
        self.actionButton = Button(title: config.actionButtonTitle, theme: theme)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        actionButton.addTarget(self, action: #selector(didTapActionButton(sender:)), for: .touchUpInside)

        headerImageView.contentMode = .scaleAspectFill
        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.distribution = .equalSpacing
        contentView.backgroundColor = .clear

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerImageView)
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
        headerImageView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.equalToSuperview()
        }
        stackView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(headerImageView.snp.bottom).offset(32)
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
    private let contentStack: UIStackView
    private let content: [NSAttributedString]

    // MARK: - Init

    init(theme: Theme, title: String, content: [NSAttributedString]) {
        self.titleLabel = Label(frame: .zero)
        self.contentStack = UIStackView()
        self.content = content

        super.init(theme: theme)

        titleLabel.text = title
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title2
        titleLabel.accessibilityTraits = .header

        contentStack.axis = .vertical
        contentStack.alignment = .top
        contentStack.distribution = .fill

        addSubview(titleLabel)
        addSubview(contentStack)

        for text in self.content {
            let label = Label(frame: .zero)
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.font = theme.fonts.body
            label.attributedText = text
            contentStack.addArrangedSubview(label)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
        }
        contentStack.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(10)
            maker.leading.trailing.equalTo(titleLabel)
            maker.bottom.equalToSuperview()
        }
    }
}

final class InfoSectionCalloutView: View {

    private let backgroundView: View

    private let contentLabel: Label
    private let iconImageView: UIImageView

    // MARK: - Init

    init(theme: Theme, content: NSAttributedString) {
        self.backgroundView = View(theme: theme)
        self.contentLabel = Label(frame: .zero)
        self.iconImageView = UIImageView(image: Image.named("Info"))
        super.init(theme: theme)

        contentLabel.attributedText = content
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping

        backgroundView.layer.cornerRadius = 8
        backgroundView.backgroundColor = theme.colors.tertiary

        addSubview(backgroundView)
        backgroundView.addSubview(contentLabel)
        backgroundView.addSubview(iconImageView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        backgroundView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.bottom.equalToSuperview()
        }
        iconImageView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.equalToSuperview().offset(16)
            maker.width.height.equalTo(24)
        }
        contentLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalToSuperview().offset(16)
            maker.leading.equalTo(iconImageView.snp.trailing).offset(18)
            maker.trailing.bottom.equalToSuperview().inset(16)
        }
    }
}

final class InfoSectionDynamicCalloutView: View {

    enum State {
        case loading(String)
        case success(String)
        case error(String, () -> ())
    }

    private let titleLabel: Label
    private let contentView: View

    // MARK: - Init

    init(theme: Theme, title: String) {
        self.titleLabel = Label(frame: .zero)
        self.contentView = View(theme: theme)
        super.init(theme: theme)

        titleLabel.text = title
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = theme.colors.tertiary

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title2

        addSubview(titleLabel)
        addSubview(contentView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
        }
        contentView.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(titleLabel)
            maker.bottom.equalToSuperview()
        }
    }

    // MARK: - Internal

    func set(state: State) {
        func add(_ view: View) {
            view.clipsToBounds = true
            view.backgroundColor = .clear

            contentView.subviews.filter {
                $0 is InfoSectionDynamicLoadingView || $0 is InfoSectionDynamicSuccessView || $0 is InfoSectionDynamicErrorView
            }.forEach {
                $0.removeFromSuperview()
            }
            contentView.addSubview(view)

            view.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        }

        switch state {
        case let .loading(title):
            let view = InfoSectionDynamicLoadingView(theme: theme, title: title)
            add(view)
        case let .success(code):
            let view = InfoSectionDynamicSuccessView(theme: theme, title: code)
            add(view)
        case let .error(error, actionHandler):
            let view = InfoSectionDynamicErrorView(theme: theme, title: error, actionHandler: actionHandler)
            add(view)
        }
    }
}

private final class InfoSectionDynamicLoadingView: View {

    private let activityIndicator: UIActivityIndicatorView
    private let loadingLabel: Label

    // MARK: - Init

    init(theme: Theme, title: String) {
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        self.loadingLabel = Label()
        super.init(theme: theme)

        loadingLabel.text = title
    }

    // MARK: - Overrides

    override func removeFromSuperview() {
        activityIndicator.startAnimating()
        super.removeFromSuperview()
    }

    override func build() {
        super.build()

        backgroundColor = .clear

        activityIndicator.startAnimating()
        loadingLabel.font = theme.fonts.subhead
        loadingLabel.textAlignment = .center

        addSubview(activityIndicator)
        addSubview(loadingLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        activityIndicator.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.height.width.equalTo(40)
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(24)
        }
        loadingLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(activityIndicator.snp.bottom).offset(12)
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.bottom.equalToSuperview().inset(12)
        }
    }
}

private final class InfoSectionDynamicSuccessView: View {

    private let titleLabel: Label

    // MARK: - Init

    init(theme: Theme, title: String) {
        self.titleLabel = Label()
        super.init(theme: theme)

        titleLabel.text = title
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        titleLabel.textAlignment = .center
        titleLabel.font = theme.fonts.largeTitle

        addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.bottom.equalToSuperview().inset(27)
            maker.leading.trailing.equalToSuperview().inset(16)
        }
    }
}

private final class InfoSectionDynamicErrorView: View {

    private var actionHandler: () -> ()

    private let titleLabel: Label
    private let actionButton: Button

    // MARK: - Init

    init(theme: Theme, title: String, actionHandler: @escaping () -> ()) {
        self.titleLabel = Label()
        self.actionButton = Button(theme: theme)
        self.actionHandler = actionHandler
        super.init(theme: theme)

        titleLabel.text = title
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = theme.fonts.subhead

        actionButton.style = .secondary
        actionButton.setTitle("Probeer opnieuw", for: .normal)
        actionButton.addTarget(self, action: #selector(didTapActionButton(sender:)), for: .touchUpInside)

        addSubview(titleLabel)
        addSubview(actionButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.equalToSuperview().inset(16)
        }
        actionButton.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }

    // MARK: - Private

    @objc private func didTapActionButton(sender: Button) {
        actionHandler()
    }
}

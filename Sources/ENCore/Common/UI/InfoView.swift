/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import SnapKit
import UIKit

struct InfoViewConfig {
    let actionButtonTitle: String
    let headerImage: UIImage?
    let showActionButton: Bool

    init(actionButtonTitle: String = "", headerImage: UIImage? = nil, showActionButton: Bool = true) {
        self.actionButtonTitle = actionButtonTitle
        self.headerImage = headerImage
        self.showActionButton = showActionButton
    }
}

final class InfoView: View {

    var actionHandler: (() -> ())?
    var isActionButtonEnabled: Bool = true {
        didSet { actionButton.isEnabled = isActionButtonEnabled }
    }

    private let scrollView: UIScrollView
    private let contentView: UIView
    private let headerBackgroundView: UIView

    private let headerImageView: UIImageView
    private let stackView: UIStackView
    private let actionButton: Button

    private let showActionButton: Bool

    // MARK: - Init

    init(theme: Theme, config: InfoViewConfig) {
        self.contentView = UIView(frame: .zero)
        self.headerImageView = UIImageView(image: config.headerImage)
        self.stackView = UIStackView(frame: .zero)
        self.scrollView = UIScrollView(frame: .zero)
        self.headerBackgroundView = UIView(frame: .zero)
        self.actionButton = Button(title: config.actionButtonTitle, theme: theme)
        self.showActionButton = config.showActionButton
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        headerImageView.contentMode = .scaleAspectFill
        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.distribution = .equalSpacing
        contentView.backgroundColor = .clear
        headerBackgroundView.backgroundColor = theme.colors.headerBackgroundBlue

        addSubview(scrollView)
        scrollView.addSubview(headerBackgroundView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerImageView)
        contentView.addSubview(stackView)

        if showActionButton {
            actionButton.addTarget(self, action: #selector(didTapActionButton(sender:)), for: .touchUpInside)
            contentView.addSubview(actionButton)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }

        headerBackgroundView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(self.snp.top)
            maker.bottom.greaterThanOrEqualTo(scrollView.snp.top)
            maker.leading.trailing.equalTo(self)
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

            if !showActionButton {
                constrainToSuperViewWithBottomMargin(maker: maker)
            }
        }
        if showActionButton {
            actionButton.snp.makeConstraints { (maker: ConstraintMaker) in
                maker.height.equalTo(48)
                maker.top.equalTo(stackView.snp.bottom).offset(16)
                maker.leading.trailing.equalToSuperview().inset(16)

                constrainToSuperViewWithBottomMargin(maker: maker)
            }
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

final class InfoSectionContentView: View {

    private let contentLabel: Label
    var linkHandler: ((String) -> ())?

    // MARK: - Init

    init(theme: Theme, content: NSAttributedString) {
        self.contentLabel = Label(frame: .zero)
        super.init(theme: theme)

        contentLabel.attributedText = content
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        contentLabel.numberOfLines = 0
        contentLabel.accessibilityTraits = .header

        addSubview(contentLabel)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapLabel(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(24)
            maker.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
        }
    }

    // MARK: - Private

    @objc
    private func didTapLabel(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let linkHandler = linkHandler else { return }

        let range = NSRange(location: 0, length: contentLabel.attributedText?.length ?? 0)

        let handlePotentialMatch: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> () = { value, range, `continue` in
            guard let value = value as? String else {
                return
            }

            if gestureRecognizer.didTapAttributedTextInLabel(label: self.contentLabel, inRange: range) {
                linkHandler(value)

                `continue`.pointee = true
            }
        }

        contentLabel.attributedText?.enumerateAttribute(.link,
                                                        in: range,
                                                        options: [],
                                                        using: handlePotentialMatch)
    }
}

final class InfoSectionStepView: View {

    private let iconImageView: UIImageView
    private let titleLabel: Label

    // MARK: - Init

    init(theme: Theme, title: String, stepImage: UIImage?) {
        self.iconImageView = UIImageView(image: stepImage)
        self.titleLabel = Label(frame: .zero)
        super.init(theme: theme)

        titleLabel.text = title
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title3
        titleLabel.accessibilityTraits = .header

        addSubview(iconImageView)
        addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(16)
            maker.top.equalToSuperview()
            maker.width.height.equalTo(32)
        }
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview().inset(16)
            maker.leading.equalTo(iconImageView.snp.trailing).offset(16)
            maker.bottom.equalToSuperview()
        }
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
        contentStack.spacing = 5

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
        self.iconImageView = UIImageView(image: .info)
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
            maker.leading.equalToSuperview().offset(20)
            maker.top.equalToSuperview().offset(16)
            maker.width.height.equalTo(24)
        }
        contentLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalToSuperview().offset(16)
            maker.leading.equalTo(iconImageView.snp.trailing).offset(12)
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

    private let iconImageView: UIImageView
    private let titleLabel: Label
    private let contentView: View

    // MARK: - Init

    init(theme: Theme, title: String, stepImage: UIImage?) {
        self.iconImageView = UIImageView(image: stepImage)
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
        titleLabel.font = theme.fonts.title3

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(contentView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(16)
            maker.top.equalToSuperview()
            maker.width.height.equalTo(32)
        }
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview().inset(16)
            maker.leading.equalTo(iconImageView.snp.trailing).offset(16)
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

private extension UITapGestureRecognizer {

    // taken from https://stackoverflow.com/questions/1256887/create-tap-able-links-in-the-nsattributedstring-of-a-uilabel
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

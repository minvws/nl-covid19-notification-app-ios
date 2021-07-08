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
    let actionButtonTitle: String?
    let secondaryButtonTitle: String?
    let headerImage: UIImage?
    let showButtons: Bool
    let stickyButtons: Bool
    let headerBackgroundViewColor: UIColor?

    init(actionButtonTitle: String? = nil,
         secondaryButtonTitle: String? = nil,
         headerImage: UIImage? = nil,
         headerBackgroundViewColor: UIColor? = nil,
         showButtons: Bool = true,
         stickyButtons: Bool = false) {
        self.actionButtonTitle = actionButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.headerImage = headerImage
        self.showButtons = showButtons
        self.stickyButtons = stickyButtons
        self.headerBackgroundViewColor = headerBackgroundViewColor
    }
}

final class InfoView: View {
    var actionHandler: (() -> ())?
    var isActionButtonEnabled: Bool = true {
        didSet { actionButton.isEnabled = isActionButtonEnabled }
    }

    var secondaryActionHandler: (() -> ())?

    var showHeader: Bool = true {
        didSet {
            headerImageView.isHidden = !showHeader
            headerBackgroundView.isHidden = !showHeader
            setupConstraints()
        }
    }

    let secondaryButton: Button?

    private let scrollView: UIScrollView
    private let contentView: UIView
    private let headerBackgroundView: UIView

    private let headerImageView: UIImageView
    private let stackView: UIStackView
    private let buttonStackView: UIStackView
    private let buttonSeparator: GradientView
    private let actionButton: Button

    private let showButtons: Bool
    private let stickyButtons: Bool
    private var itemSpacing: CGFloat

    // MARK: - Init

    init(theme: Theme, config: InfoViewConfig, itemSpacing: CGFloat = 40) {
        contentView = UIView(frame: .zero)
        headerImageView = UIImageView(image: config.headerImage)
        stackView = UIStackView(frame: .zero)
        buttonStackView = UIStackView(frame: .zero)
        scrollView = UIScrollView(frame: .zero)
        headerBackgroundView = UIView(frame: .zero)
        actionButton = Button(title: config.actionButtonTitle ?? "", theme: theme)
        buttonSeparator = GradientView(startColor: UIColor.white.withAlphaComponent(0), endColor: UIColor.black.withAlphaComponent(0.1))
        if let title = config.secondaryButtonTitle {
            secondaryButton = Button(title: title, theme: theme)
        } else {
            secondaryButton = nil
        }
        showButtons = config.showButtons
        stickyButtons = config.stickyButtons
        headerBackgroundView.backgroundColor = config.headerBackgroundViewColor ?? theme.colors.headerBackgroundBlue
        self.itemSpacing = itemSpacing
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        headerImageView.contentMode = .scaleAspectFill
        stackView.axis = .vertical
        stackView.spacing = itemSpacing
        stackView.distribution = .equalSpacing
        contentView.backgroundColor = .clear

        buttonStackView.axis = .vertical
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually

        addSubview(scrollView)
        scrollView.addSubview(headerBackgroundView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerImageView)
        contentView.addSubview(stackView)

        if showButtons {
            actionButton.addTarget(self, action: #selector(didTapActionButton(sender:)), for: .touchUpInside)
            if let secondaryButton = secondaryButton {
                secondaryButton.addTarget(self, action: #selector(didTapSecondaryButton(sender:)), for: .touchUpInside)
                secondaryButton.style = .secondary
                buttonStackView.addArrangedSubview(secondaryButton)
            }

            buttonStackView.addArrangedSubview(actionButton)

            if stickyButtons {
                addSubview(buttonSeparator)
                addSubview(buttonStackView)
            } else {
                contentView.addSubview(buttonStackView)
            }
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.remakeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.equalToSuperview()

            if !stickyButtons {
                maker.bottom.equalToSuperview()
            }
        }

        headerBackgroundView.snp.remakeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(self.snp.top)
            maker.bottom.greaterThanOrEqualTo(scrollView.snp.top)
            maker.leading.trailing.equalTo(self)
        }

        contentView.snp.remakeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(scrollView)
            maker.bottom.equalTo(scrollView)
            maker.leading.trailing.equalTo(self)
        }

        let imageAspectRatio = headerImageView.image?.aspectRatio ?? 1.0
        headerImageView.snp.remakeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(headerImageView.snp.width).dividedBy(imageAspectRatio)
        }

        stackView.snp.remakeConstraints { (maker: ConstraintMaker) in
            if showHeader {
                maker.top.equalTo(headerImageView.snp.bottom).offset(24)
            } else {
                maker.top.equalToSuperview()
            }
            maker.leading.trailing.equalToSuperview()

            if !showButtons {
                constrainToSuperViewWithBottomMargin(maker: maker)
            }

            if showButtons, stickyButtons {
                maker.bottom.equalToSuperview().inset(16)
            }
        }
        if showButtons {
            buttonStackView.snp.remakeConstraints { (maker: ConstraintMaker) in
                let count = buttonStackView.arrangedSubviews.count
                if count > 0 {
                    let height = Float((count * 48) + ((count - 1) * 20))
                    maker.height.equalTo(height)
                }
                maker.leading.trailing.equalToSuperview().inset(16)

                if stickyButtons {
                    maker.top.equalTo(scrollView.snp.bottom).offset(16)
                    constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
                } else {
                    constrainToSuperViewWithBottomMargin(maker: maker)
                    maker.top.equalTo(stackView.snp.bottom).offset(16)
                }
            }
        }

        if showButtons, stickyButtons {
            buttonSeparator.snp.remakeConstraints { maker in
                maker.bottom.equalTo(buttonStackView.snp.top).offset(-16)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(16)
            }
        }
    }

    // MARK: - Internal

    func addSections(_ views: [UIView]) {
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }
    
    func removeAllSections() {
        stackView.arrangedSubviews.forEach({ $0.removeFromSuperview()})
    }

    // MARK: - Private

    @objc private func didTapActionButton(sender: Button) {
        actionHandler?()
    }

    @objc private func didTapSecondaryButton(sender: Button) {
        secondaryActionHandler?()
    }
}

final class InfoSectionContentView: View, UITextViewDelegate {
    private let contentTextView: TextView
    var linkHandler: ((String) -> ())?

    // MARK: - Init

    init(theme: Theme, content: NSAttributedString) {
        contentTextView = TextView(frame: .zero)

        super.init(theme: theme)

        contentTextView.attributedText = content
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let linkHandler = linkHandler {
            linkHandler(URL.absoluteString)
            return false
        }
        return true
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        contentTextView.delegate = self
        contentTextView.isEditable = false
        contentTextView.isScrollEnabled = false
        addSubview(contentTextView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentTextView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(0)
            maker.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
        }
    }
}

final class InfoSectionStepView: View {
        
    private let iconImageView: UIImageView
    private let titleLabel: Label
    private let descriptionLabel: Label
    private let progressLine: View
    private let isLastStep: Bool
    
    private var buttonActionHandler: (() -> ())?
    private var buttonTitle: String?
    private var disabledButtonTitle: String?
    
    private let stepImage: UIImage?
    private let disabledStepImage: UIImage?
    private let loadingIndicatorTitle: String?
    
    var buttonEnabled: Bool = true {
        didSet {
            actionButton?.isEnabled = buttonEnabled
        }
    }
    
    var isDisabled: Bool {
        didSet {
            updateEnabledState()
        }
    }
    
    private func updateEnabledState() {
        iconImageView.image = isDisabled ? disabledStepImage : stepImage
        actionButton?.isEnabled = !isDisabled
        titleLabel.textColor = isDisabled ? theme.colors.disabled : theme.colors.gray
        descriptionLabel.textColor = isDisabled ? theme.colors.disabled : theme.colors.gray
    }
    
    private lazy var actionButton: Button? = {
        guard let buttonActionHandler = buttonActionHandler, let buttonTitle = buttonTitle else {
            return nil
        }
        
        let button = Button(title: buttonTitle, theme: theme)
        button.setTitle(disabledButtonTitle, for: .disabled)
        button.isEnabled = !isDisabled
        button.action = buttonActionHandler
        return button
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.axis = .vertical
        stack.spacing = 16
        stack.addArrangedSubview(titleLabel)
        if let descriptionText = descriptionLabel.text, !descriptionText.isEmpty {
            stack.addArrangedSubview(descriptionLabel)
        }
        if let actionButton = actionButton {
            stack.addArrangedSubview(actionButton)
        }
        if let loadingIndicator = loadingIndicator {
            stack.addArrangedSubview(loadingIndicator)
        }
        return stack
    }()
    
    private lazy var loadingIndicator: UIView? = {
        if let loadingIndicatorTitle = loadingIndicatorTitle {
            return InfoSectionDynamicLoadingView(theme: theme, title: loadingIndicatorTitle)
        } else {
            return nil
        }
    }()

    // MARK: - Init

    init(theme: Theme,
         title: String,
         description: String? = nil,
         stepImage: UIImage?,
         disabledStepImage: UIImage? = nil,
         isLastStep: Bool = false,
         buttonTitle: String? = nil,
         disabledButtonTitle: String? = nil,
         buttonActionHandler: (() -> ())? = nil,
         isDisabled: Bool = false,
         loadingIndicatorTitle: String? = nil) {
        
        iconImageView = UIImageView(image: isDisabled ? disabledStepImage : stepImage)
        titleLabel = Label(frame: .zero)
        descriptionLabel = Label(frame: .zero)
        progressLine = View(theme: theme)
        
        self.stepImage = stepImage
        self.disabledStepImage = disabledStepImage
        self.isDisabled = isDisabled
        self.isLastStep = isLastStep
        self.buttonActionHandler = buttonActionHandler
        self.buttonTitle = buttonTitle
        self.disabledButtonTitle = disabledButtonTitle
        self.loadingIndicatorTitle = loadingIndicatorTitle
        
        titleLabel.text = title
        descriptionLabel.text = description
        
        super.init(theme: theme)
        
        updateEnabledState()
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title3
        titleLabel.accessibilityTraits = .header
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = theme.fonts.body
        descriptionLabel.accessibilityTraits = .staticText

        progressLine.backgroundColor = theme.colors.tertiary
        progressLine.isHidden = isLastStep
        
        addSubview(iconImageView)
        addSubview(progressLine)
        addSubview(contentStackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(16)
            maker.top.equalToSuperview()
            maker.width.height.equalTo(32)
        }
        
        progressLine.snp.makeConstraints { maker in
            maker.centerX.equalTo(iconImageView)
            maker.top.equalTo(iconImageView.snp.bottom).offset(2)
            maker.bottom.equalToSuperview()
            maker.width.equalTo(4)
        }
        
        var bottomSpacing: CGFloat = 40
        if isLastStep {
            bottomSpacing = 0
        }
        if loadingIndicatorTitle != nil {
            bottomSpacing = 20
        }
        
        contentStackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview().inset(16)
            maker.leading.equalTo(iconImageView.snp.trailing).offset(16)
            maker.bottom.equalToSuperview().inset(bottomSpacing)
        }
        
        if let button = actionButton {
            button.snp.makeConstraints { maker in
                maker.height.equalTo(48)
            }
        }
    }
}

final class InfoSectionTextView: View {
    private let titleLabel: Label
    private let contentStack: UIStackView
    private let content: [NSAttributedString]
    private let contentAccessibilityTraits: UIAccessibilityTraits?

    // MARK: - Init

    init(theme: Theme, title: String, content: [NSAttributedString], contentAccessibilityTraits: UIAccessibilityTraits? = nil) {
        titleLabel = Label(frame: .zero)
        contentStack = UIStackView()
        self.content = content
        self.contentAccessibilityTraits = contentAccessibilityTraits

        super.init(theme: theme)

        titleLabel.text = title
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title2
        titleLabel.accessibilityTraits = .header
        titleLabel.textAlignment = Localization.isRTL ? .right : .left

        contentStack.axis = .vertical
        contentStack.alignment = .top
        contentStack.distribution = .fill
        contentStack.spacing = 5

        addSubview(titleLabel)
        addSubview(contentStack)

        for text in content {
            let label = Label(frame: .zero)
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.font = theme.fonts.body
            label.textColor = theme.colors.gray
            label.attributedText = text            
            if let traits = contentAccessibilityTraits {
                label.accessibilityTraits = traits
            }
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
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
            maker.leading.trailing.equalTo(titleLabel)
            maker.bottom.equalToSuperview()
        }
    }
}

final class InfoSectionTextViewWithLinks: View, UITextViewDelegate {

    private let titleLabel: Label
    private let contentStack: UIStackView
    private let content: [NSAttributedString]
    private let linkHandler: ((String) -> ())
    
    // MARK: - Init

    init(theme: Theme, title: String, content: [NSAttributedString], linkHandler: @escaping ((String) -> ())) {
        self.titleLabel = Label(frame: .zero)
        self.contentStack = UIStackView()
        self.content = content
        self.linkHandler = linkHandler

        super.init(theme: theme)

        titleLabel.text = title
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title2
        titleLabel.accessibilityTraits = .header
        titleLabel.textAlignment = Localization.isRTL ? .right : .left

        contentStack.axis = .vertical
        contentStack.alignment = .top
        contentStack.distribution = .fill
        contentStack.spacing = 0

        addSubview(titleLabel)
        addSubview(contentStack)

        for text in self.content {
            let textView = TextView(frame: .zero)
            textView.delegate = self
            textView.isEditable = false
            textView.isSelectable = true
            textView.isScrollEnabled = false
            textView.isAccessibilityElement = true
            textView.font = theme.fonts.body
            textView.textColor = theme.colors.gray
            textView.attributedText = text
            contentStack.addArrangedSubview(textView)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
        }
        contentStack.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
            maker.leading.trailing.equalTo(titleLabel)
            maker.bottom.equalToSuperview()
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {        
        linkHandler(URL.absoluteString)
        return false
    }
}

final class InfoSectionContentTextView: View {
    private let contentStack: UIStackView
    private let content: [NSAttributedString]

    // MARK: - Init

    init(theme: Theme, content: [NSAttributedString]) {
        contentStack = UIStackView()
        self.content = content

        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        contentStack.axis = .vertical
        contentStack.alignment = .top
        contentStack.distribution = .fill
        contentStack.spacing = 5

        addSubview(contentStack)

        for text in content {
            let label = Label(frame: .zero)
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.font = theme.fonts.body
            label.textColor = theme.colors.gray
            label.attributedText = text
            contentStack.addArrangedSubview(label)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentStack.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
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
        backgroundView = View(theme: theme)
        contentLabel = Label(frame: .zero)
        iconImageView = UIImageView(image: .info)
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
        case disabled
        case loading(String)
        case success(String)
        case error(String, () -> ())
    }

    private let iconImageView: UIImageView
    private let titleLabel: Label
    private let contentView: View
    private let progressLine: View
    
    private let stepImage: UIImage?
    private let disabledStepImage: UIImage?
        
    // MARK: - Init

    init(theme: Theme, title: String, stepImage: UIImage?, disabledStepImage: UIImage? = nil, initialState: State = .disabled) {
        self.stepImage = stepImage
        self.disabledStepImage = disabledStepImage
        
        iconImageView = UIImageView(image: stepImage)
        titleLabel = Label(frame: .zero)
        contentView = View(theme: theme)
        progressLine = View(theme: theme)
        
        super.init(theme: theme)

        titleLabel.text = title
        
        set(state: initialState)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = theme.colors.tertiary

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title3

        progressLine.backgroundColor = theme.colors.tertiary

        addSubview(iconImageView)
        addSubview(progressLine)
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
        progressLine.snp.makeConstraints { maker in
            maker.centerX.equalTo(iconImageView)
            maker.top.equalTo(iconImageView.snp.bottom).offset(2)
            maker.bottom.equalToSuperview()
            maker.width.equalTo(4)
        }
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview().inset(16)
            maker.leading.equalTo(iconImageView.snp.trailing).offset(16)
        }
        contentView.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(titleLabel)
            maker.bottom.equalToSuperview().inset(40)
        }
    }

    // MARK: - Internal

    func set(state: State) {
        func add(_ view: View) {
            view.clipsToBounds = true
            view.backgroundColor = .clear

            contentView.subviews.filter {
                $0 is InfoSectionDynamicLoadingView || $0 is InfoSectionDynamicSuccessView || $0 is InfoSectionDynamicErrorView || $0 is InfoSectionDynamicDisabledView
            }.forEach {
                $0.removeFromSuperview()
            }
            contentView.addSubview(view)

            view.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        }

        switch state {
        case .disabled:
            iconImageView.image = disabledStepImage
            titleLabel.textColor = theme.colors.disabled
            
            let view = InfoSectionDynamicDisabledView(theme: theme)
            add(view)
        case let .loading(title):
            iconImageView.image = stepImage
            titleLabel.textColor = theme.colors.gray
            
            let view = InfoSectionDynamicLoadingView(theme: theme, title: title)
            add(view)
        case let .success(code):
            iconImageView.image = stepImage
            titleLabel.textColor = theme.colors.gray
            
            let view = InfoSectionDynamicSuccessView(theme: theme, title: code)
            add(view)
        case let .error(error, actionHandler):
            iconImageView.image = stepImage
            titleLabel.textColor = theme.colors.gray
            
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
        if #available(iOS 13.0, *) {
            self.activityIndicator = UIActivityIndicatorView(style: .large)
        } else {
            activityIndicator = UIActivityIndicatorView(style: .gray)
        }
        loadingLabel = Label()
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

private final class InfoSectionDynamicDisabledView: View {
    private let stackView: UIStackView
    
    // MARK: - Init

    override init(theme: Theme) {
        stackView = UIStackView(frame: .zero)
        
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        
        (0..<3).forEach { _ in stackView.addArrangedSubview(UIImageView(image: .star)) }
        stackView.addArrangedSubview(UIImageView(image: .dash))
        (0..<2).forEach { _ in stackView.addArrangedSubview(UIImageView(image: .star)) }
        stackView.addArrangedSubview(UIImageView(image: .dash))
        (0..<2).forEach { _ in stackView.addArrangedSubview(UIImageView(image: .star)) }
        addSubview(stackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        stackView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.bottom.equalToSuperview().inset(27)
            maker.centerX.equalToSuperview()
        }
    }
}

private final class InfoSectionDynamicSuccessView: View {
    private let titleLabel: Label

    // MARK: - Init

    init(theme: Theme, title: String) {
        titleLabel = Label()
        super.init(theme: theme)

        titleLabel.text = title.asGGDkey
        titleLabel.textCanBeCopied(charactersToRemove: "-")

        let accessibilityText = title.replacingOccurrences(of: "-", with: "").lowercased()

        if #available(iOS 13.0, *) {
            titleLabel.accessibilityAttributedLabel = NSAttributedString(string: accessibilityText, attributes: [.accessibilitySpeechSpellOut: true])
        } else {
            titleLabel.accessibilityAttributedLabel = NSAttributedString(string: accessibilityText.stringForSpelling, attributes: [.accessibilitySpeechPunctuation: false])
        }
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
        titleLabel = Label()
        actionButton = Button(theme: theme)
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
        actionButton.setTitle(.retry, for: .normal)
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

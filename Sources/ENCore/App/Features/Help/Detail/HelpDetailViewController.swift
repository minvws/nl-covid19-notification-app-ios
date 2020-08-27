/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit
import WebKit

final class HelpDetailViewController: ViewController, Logging, UIAdaptivePresentationControllerDelegate {

    init(listener: HelpDetailListener,
         shouldShowEnableAppButton: Bool,
         question: HelpQuestion,
         linkedQuestions: [HelpQuestion] = [],
         theme: Theme) {
        self.listener = listener
        self.shouldShowEnableAppButton = shouldShowEnableAppButton
        self.question = question
        self.linkedQuestions = linkedQuestions

        super.init(theme: theme)
        navigationItem.rightBarButtonItem = closeBarButtonItem
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        linkedQuestions.forEach { [weak self] question in
            self?.internalView.append(linkedQuestion: question, tapHandler: { print(question.question) })
        }

        internalView.titleLabel.attributedText = .makeFromHtml(text: question.question,
                                                               font: theme.fonts.largeTitle,
                                                               textColor: theme.colors.gray,
                                                               textAlignment: Localization.isRTL ? .right : .left)

        internalView.contentLabel.attributedText = .makeFromHtml(text: question.answer,
                                                                 font: theme.fonts.body,
                                                                 textColor: theme.colors.gray,
                                                                 textAlignment: Localization.isRTL ? .right : .left)

        internalView.acceptButton.addTarget(self, action: #selector(acceptButtonPressed), for: .touchUpInside)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.helpDetailRequestsDismissal(shouldDismissViewController: false)
    }

    @objc func acceptButtonPressed() {
        listener?.helpDetailDidTapEnableAppButton()
    }

    @objc func didTapClose() {
        listener?.helpDetailRequestsDismissal(shouldDismissViewController: true)
    }

    // MARK: - Private

    private lazy var internalView: HelpView = HelpView(theme: theme, shouldDisplayButton: shouldShowEnableAppButton)
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapClose))
    private weak var listener: HelpDetailListener?

    private let shouldShowEnableAppButton: Bool
    private let question: HelpQuestion
    private let linkedQuestions: [HelpQuestion]
}

private final class HelpView: View {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    lazy var contentLabel: Label = {
        let label = Label()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var acceptButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.title = .helpAcceptButtonTitle
        return button
    }()

    init(theme: Theme, shouldDisplayButton: Bool) {
        self.shouldDisplayButton = shouldDisplayButton
        super.init(theme: theme)
    }

    override func build() {
        super.build()
        hasBottomMargin = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)

        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(linkedQuestionsContainer)

        if shouldDisplayButton {
            addSubview(acceptButton)
        }

        linkedQuestionsViewWrapper.addSubview(linkedQuestionsTitle)
    }

    override func setupConstraints() {
        super.setupConstraints()

        let bottomAnchor = shouldDisplayButton ? acceptButton.snp.top : snp.bottom

        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomAnchor)
        }

        contentView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.greaterThanOrEqualToSuperview()
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.leading.trailing.width.equalToSuperview().inset(16)
        }

        contentLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.width.equalToSuperview().inset(16)
        }

        linkedQuestionsContainer.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.width.equalToSuperview()
            maker.top.greaterThanOrEqualTo(contentLabel.snp.bottom).offset(16)
        }

        if shouldDisplayButton {
            acceptButton.snp.makeConstraints { maker in

                maker.bottom.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(50)
            }
        }

        linkedQuestionsTitle.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(16)
        }
    }

    func append(linkedQuestion: HelpQuestion, tapHandler: () -> ()) {
        if linkedQuestionsContainer.subviews.isEmpty {
            linkedQuestionsContainer.addArrangedSubview(linkedQuestionsViewWrapper)
        }
    }

    // MARK: - Private

    private let shouldDisplayButton: Bool

    private lazy var linkedQuestionsViewWrapper = View(theme: theme)

    private lazy var scrollView: UIScrollView = {
        let scrollview = UIScrollView()
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        return scrollview
    }()

    private lazy var contentView: View = {
        let view = View(theme: theme)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var linkedQuestionsContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var linkedQuestionsTitle: Label = {
        let label = Label()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.subheadBold
        label.textColor = self.theme.colors.primary
        label.accessibilityTraits = .header
        label.text = "Less ook"
        return label
    }()
}

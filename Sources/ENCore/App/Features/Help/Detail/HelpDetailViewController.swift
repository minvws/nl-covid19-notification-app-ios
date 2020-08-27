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
         theme: Theme) {
        self.listener = listener
        self.shouldShowEnableAppButton = shouldShowEnableAppButton
        self.question = question

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
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)

        scrollView.addSubview(titleLabel)
        scrollView.addSubview(contentLabel)

        if shouldDisplayButton {
            addSubview(acceptButton)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        let bottomAnchor = shouldDisplayButton ? acceptButton.snp.top : snp.bottom

        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomAnchor)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.leading.trailing.width.equalToSuperview().inset(16)
        }

        contentLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.bottom.width.equalToSuperview().inset(16)
        }

        if shouldDisplayButton {
            acceptButton.snp.makeConstraints { maker in
                maker.bottom.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(50)
            }
        }
    }

    // MARK: - Private

    private let shouldDisplayButton: Bool

    private let scrollView = UIScrollView()
}

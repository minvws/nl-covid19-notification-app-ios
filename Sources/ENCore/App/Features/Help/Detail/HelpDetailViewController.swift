/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit
import WebKit

final class HelpDetailViewController: ViewController, Logging, UIAdaptivePresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

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

        headerView.label.text = "Less ook" // TODO: localize string
        internalView.tableView.delegate = self
        internalView.tableView.dataSource = self

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        internalView.tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        internalView.tableView.removeObserver(self, forKeyPath: "contentSize")
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return question.linkedQuestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = HelpTableViewCell(theme: theme, reuseIdentifier: "HelpDetailQuestionCell")

        cell.textLabel?.text = question.linkedQuestions[indexPath.row].question
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = theme.fonts.body
        cell.textLabel?.accessibilityTraits = .header

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return question.linkedQuestions.isEmpty ? UIView() : headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        listener?.helpDetailRequestRedirect(to: question.linkedQuestions[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.internalView.tableView, keyPath == "contentSize" {
                internalView.updateTableViewHeight()
            }
        }
    }

    // MARK: - Private

    private lazy var internalView: HelpView = HelpView(theme: theme, shouldDisplayButton: shouldShowEnableAppButton)
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapClose))
    private weak var listener: HelpDetailListener?

    private let shouldShowEnableAppButton: Bool
    private let question: HelpQuestion

    private lazy var headerView: HelpTableViewSectionHeaderView = HelpTableViewSectionHeaderView(theme: self.theme)
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

    lazy var tableView = HelpTableView()

    init(theme: Theme, shouldDisplayButton: Bool) {
        self.shouldDisplayButton = shouldDisplayButton
        super.init(theme: theme)
    }

    override func build() {
        super.build()
        hasBottomMargin = true
        tableView.isScrollEnabled = false

        addSubview(scrollView)

        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(tableView)

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

        contentView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.greaterThanOrEqualToSuperview().priority(.low)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.leading.trailing.width.equalToSuperview().inset(16)
        }

        contentLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.width.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.width.equalToSuperview()
            maker.top.greaterThanOrEqualTo(contentLabel.snp.bottom).offset(16)
            maker.height.equalTo(0)
        }

        if shouldDisplayButton {
            acceptButton.snp.makeConstraints { maker in
                maker.bottom.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(50)
            }
        }
    }

    func updateTableViewHeight() {
        tableView.snp.updateConstraints { maker in
            maker.height.equalTo(tableView.contentSize.height)
        }
    }

    // MARK: - Private

    private let shouldDisplayButton: Bool

    private lazy var scrollView: UIScrollView = {
        let scrollview = UIScrollView()
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        scrollview.contentInsetAdjustmentBehavior = .never
        return scrollview
    }()

    private lazy var contentView: View = {
        let view = View(theme: theme)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
}

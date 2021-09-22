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
         entry: HelpDetailEntry,
         theme: Theme) {
        self.listener = listener
        self.shouldShowEnableAppButton = shouldShowEnableAppButton
        self.entry = entry
        self.linkedContentTableViewManager = LinkedContentTableViewManager(content: entry.linkedEntries, theme: theme)

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

        linkedContentTableViewManager.selectedContentHandler = { [weak self] selectedContent in
            self?.listener?.helpDetailRequestRedirect(to: selectedContent)
        }

        internalView.titleLabel.attributedText = .makeFromHtml(text: entry.title,
                                                               font: theme.fonts.largeTitle,
                                                               textColor: theme.colors.textPrimary,
                                                               textAlignment: Localization.isRTL ? .right : .left)

        internalView.contentLabel.attributedText = .makeFromHtml(text: entry.answer,
                                                                 font: theme.fonts.body,
                                                                 textColor: theme.colors.textSecondary,
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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.internalView.tableView, keyPath == "contentSize" {
                internalView.updateTableViewHeight()
            }
        }
    }

    // MARK: - Private

    private lazy var internalView: HelpView = HelpView(theme: theme,
                                                       linkedContentTableViewManager: linkedContentTableViewManager,
                                                       shouldDisplayButton: shouldShowEnableAppButton)
    private lazy var closeBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapClose))
    private weak var listener: HelpDetailListener?

    private let shouldShowEnableAppButton: Bool
    private let entry: HelpDetailEntry
    private let linkedContentTableViewManager: LinkedContentTableViewManager
}

private final class HelpView: View {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    lazy var contentLabel: SplitTextView = {
        let textView = SplitTextView(theme: theme)
        return textView
    }()

    lazy var acceptButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.title = .helpAcceptButtonTitle
        return button
    }()

    lazy var tableView = LinkedContentTableView(manager: tableViewManager)

    init(theme: Theme, linkedContentTableViewManager: LinkedContentTableViewManager, shouldDisplayButton: Bool) {
        self.shouldDisplayButton = shouldDisplayButton
        self.tableViewManager = linkedContentTableViewManager
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

        scrollView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.equalToSuperview()

            let bottomAnchor = shouldDisplayButton ? acceptButton.snp.top : snp.bottom
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
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.greaterThanOrEqualTo(50)
                constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
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
    private let tableViewManager: LinkedContentTableViewManager

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

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
        self.shouldDisplayLinkedQuestions = entry.linkedEntries.isEmpty == false
        self.linkedContentTableViewManager = LinkedContentTableViewManager(content: entry.linkedEntries, theme: theme)

        self.internalView = HelpView(theme: theme,
                                     entry: entry,
                                     linkedContentTableViewManager: linkedContentTableViewManager,
                                     shouldDisplayButton: shouldShowEnableAppButton)
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

        internalView.acceptButton.addTarget(self, action: #selector(acceptButtonPressed), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldDisplayLinkedQuestions {
            internalView.tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if shouldDisplayLinkedQuestions {
            internalView.tableView.removeObserver(self, forKeyPath: "contentSize")
        }
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

    private var internalView: HelpView
    private lazy var closeBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapClose))
    private weak var listener: HelpDetailListener?

    private let shouldDisplayLinkedQuestions: Bool
    private let shouldShowEnableAppButton: Bool
    private let linkedContentTableViewManager: LinkedContentTableViewManager
}

private final class HelpView: View {

<<<<<<< HEAD
=======
    lazy var titleLabel: Label = {
        let label = Label()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    lazy var contentLabel: SplitTextView = {
        let textView = SplitTextView(theme: theme)
        return textView
    }()

>>>>>>> 506e9ca1 (Added keyboard support for "Veelgestelde vragen" screen)
    lazy var acceptButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.title = .helpAcceptButtonTitle
        return button
    }()

    private var entry: HelpDetailEntry
    private var infoView: InfoView
    lazy var tableView = LinkedContentTableView(manager: tableViewManager)
    private lazy var tableViewWrapperView = View(theme: theme)

    init(theme: Theme, entry: HelpDetailEntry, linkedContentTableViewManager: LinkedContentTableViewManager, shouldDisplayButton: Bool) {
        self.shouldDisplayButton = shouldDisplayButton
        self.tableViewManager = linkedContentTableViewManager
        self.entry = entry

        let config = InfoViewConfig(showButtons: false)
        self.infoView = InfoView(theme: theme, config: config)
        self.infoView.showHeader = false

        super.init(theme: theme)
    }

    override func build() {
        super.build()
        hasBottomMargin = true
        tableView.isAccessibilityElement = true
        tableView.isScrollEnabled = false

<<<<<<< HEAD
        tableViewWrapperView.addSubview(tableView)

        infoView.addSections([
            faqContent(),
            tableViewWrapperView
        ])
=======
        isAccessibilityElement = false

        scrollView.isAccessibilityElement = false
        addSubview(scrollView)

        contentView.isAccessibilityElement = false
        scrollView.addSubview(contentView)
>>>>>>> 506e9ca1 (Added keyboard support for "Veelgestelde vragen" screen)

        addSubview(infoView)

        if shouldDisplayButton {
            addSubview(acceptButton)
        }
    }

    private func faqContent() -> InfoSectionTextView {
        InfoSectionTextView(theme: theme,
                            useLargeTitle: true,
                            title: entry.title,
                            content: .makeFromHtml(text: entry.answer,
                                                   font: theme.fonts.body,
                                                   textColor: theme.colors.textSecondary,
                                                   textAlignment: Localization.isRTL ? .right : .left))
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.bottom.equalToSuperview()
        }

        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0).priority(.high)
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
            maker.height.equalTo(tableView.contentSize.height).priority(.high)
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

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit
import WebKit

final class AppInformationViewController: ViewController {

    init(listener: AppInformationListener, linkedContent: [LinkedContent], theme: Theme) {
        self.listener = listener
        self.linkedContentTableViewManager = LinkedContentTableViewManager(content: linkedContent, theme: theme)
        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = self.navigationController?.navigationItem.rightBarButtonItem

        linkedContentTableViewManager.selectedContentHandler = { [weak self] selectedContent in
            self?.listener?.appInformationRequestRedirect(to: selectedContent)
        }

        internalView.technicalInformationButton.action = { [weak self] in
            self?.listener?.appInformationRequestsToTechnicalInformation()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        internalView.tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        internalView.tableView.removeObserver(self, forKeyPath: "contentSize")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.internalView.tableView, keyPath == "contentSize" {
                internalView.updateTableViewHeight()
            }
        }
    }

    // MARK: - Private

    private weak var listener: AppInformationListener?
    private lazy var internalView: AppInformationView = AppInformationView(theme: self.theme, linkedContentTableViewManager: linkedContentTableViewManager)

    private let linkedContentTableViewManager: LinkedContentTableViewManager
}

private final class AppInformationView: View {

    init(theme: Theme, linkedContentTableViewManager: LinkedContentTableViewManager) {
        self.tableViewManager = linkedContentTableViewManager
        super.init(theme: theme)
    }

    override func build() {
        super.build()
        technicalInformationButton.backgroundColor = theme.colors.cardBackgroundOrange

        addSubview(scrollableStackView)

        tableViewWrapperView.addSubview(tableView)
        buttonWrapperView.addSubview(hiddenButtonHeaderView)
        buttonWrapperView.addSubview(technicalInformationButton)

        scrollableStackView.attributedTitle = String.helpWhatAppDoesTitle.attributed()
        scrollableStackView.addSections([
            protectView,
            notifyView,
            bluetoothView,
            cycleExampleView,
            trainExampleView,
            buttonWrapperView,
            tableViewWrapperView
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollableStackView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.bottom.equalToSuperview()
        }

        hiddenButtonHeaderView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
            maker.width.height.equalTo(1)
        }

        technicalInformationButton.snp.makeConstraints { maker in
            maker.top.equalTo(hiddenButtonHeaderView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.width.equalToSuperview()
            maker.height.equalTo(0)
        }
    }

    func updateTableViewHeight() {
        tableView.snp.updateConstraints { maker in
            maker.height.equalTo(tableView.contentSize.height)
        }
    }

    lazy var tableView = LinkedContentTableView(manager: tableViewManager)

    lazy var technicalInformationButton = CardButton(title: .aboutTechnicalInformationTitle,
                                                     subtitle: .aboutTechnicalInformationDescription,
                                                     image: .aboutTechnicalInformation,
                                                     theme: theme)

    // MARK: - Private

    private lazy var scrollableStackView = ScrollableStackView(theme: theme)

    private lazy var protectView = InformationCardView(theme: theme,
                                                       image: UIImage.illustrationSitWalkCycle,
                                                       title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesProtectTitle, font: theme.fonts.title2, textColor: theme.colors.textPrimary, textAlignment: Localization.textAlignment),
                                                       message: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesProtectDescription, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.textAlignment))

    private lazy var notifyView = InformationCardView(theme: theme,
                                                      image: UIImage.illustrationNotification,
                                                      title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesNotifyTitle, font: theme.fonts.title2, textColor: theme.colors.textPrimary, textAlignment: Localization.textAlignment),
                                                      message: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesNotifyDescription, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.textAlignment))

    private lazy var bluetoothView = InformationCardView(theme: theme,
                                                         image: UIImage.illustrationBluetooth,
                                                         title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesBluetoothTitle, font: theme.fonts.title2, textColor: theme.colors.textPrimary, textAlignment: Localization.textAlignment),
                                                         message: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesBluetoothDescription, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.textAlignment))

    private lazy var cycleExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.illustrationCycle,
                                                            pretitle: String.example.attributed(),
                                                            title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesExampleCycleTitle, font: theme.fonts.title2, textColor: theme.colors.textPrimary, textAlignment: Localization.textAlignment),
                                                            message: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesExampleCycleDescription, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.textAlignment))

    private lazy var trainExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.illustrationTrain,
                                                            pretitle: String.example.attributed(),
                                                            title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesExampleTrainTitle, font: theme.fonts.title2, textColor: theme.colors.textPrimary, textAlignment: Localization.textAlignment),
                                                            message: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesExampleTrainDescription, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.textAlignment))

    private lazy var hiddenButtonHeaderView: View = {
        let view = View(theme: theme)
        view.isAccessibilityElement = true
        view.accessibilityLabel = .aboutWebsiteTitle
        view.accessibilityTraits = .header
        return view
    }()

    private lazy var buttonWrapperView = View(theme: theme)
    private lazy var tableViewWrapperView = View(theme: theme)
    private let tableViewManager: LinkedContentTableViewManager
}

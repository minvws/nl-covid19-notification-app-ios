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
        technicalInformationButton.backgroundColor = theme.colors.lightOrange

        addSubview(scrollableStackView)

        tableViewWrapperView.addSubview(tableView)
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

        technicalInformationButton.snp.makeConstraints { maker in
            maker.top.leading.trailing.bottom.equalToSuperview().inset(16)
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
                                                       image: UIImage.appInformationProtect,
                                                       title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesProtectTitle, font: theme.fonts.title2, textColor: .black),
                                                       message: String.helpWhatAppDoesProtectDescription.attributed())

    private lazy var notifyView = InformationCardView(theme: theme,
                                                      image: UIImage.appInformationNotify,
                                                      title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesNotifyTitle, font: theme.fonts.title2, textColor: .black),
                                                      message: String.helpWhatAppDoesNotifyDescription.attributed())

    private lazy var bluetoothView = InformationCardView(theme: theme,
                                                         image: UIImage.appInformationBluetooth,
                                                         title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesBluetoothTitle, font: theme.fonts.title2, textColor: .black),
                                                         message: String.helpWhatAppDoesBluetoothDescription.attributed())

    private lazy var cycleExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.appInformationExampleCycle,
                                                            pretitle: String.example.attributed(),
                                                            title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesExampleCycleTitle, font: theme.fonts.title2, textColor: .black),
                                                            message: String.helpWhatAppDoesExampleCycleDescription.attributed())

    private lazy var trainExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.appInformationExampleTrain,
                                                            pretitle: String.example.attributed(),
                                                            title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesExampleTrainTitle, font: theme.fonts.title2, textColor: .black),
                                                            message: String.helpWhatAppDoesExampleTrainDescription.attributed())

    private lazy var buttonWrapperView = View(theme: theme)
    private lazy var tableViewWrapperView = View(theme: theme)
    private let tableViewManager: LinkedContentTableViewManager
}

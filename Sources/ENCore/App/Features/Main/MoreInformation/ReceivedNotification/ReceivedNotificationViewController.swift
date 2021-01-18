/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import SnapKit
import UIKit

/// @mockable
protocol ReceivedNotificationViewControllable: ViewControllable {}

final class ReceivedNotificationViewController: ViewController, ReceivedNotificationViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: ReceivedNotificationListener,
         linkedContent: [LinkedContent],
         actionButtonTitle: String?, theme: Theme,
         interfaceOrientationStream: InterfaceOrientationStreaming) {
        self.listener = listener
        self.linkedContentTableViewManager = LinkedContentTableViewManager(content: linkedContent, theme: theme)
        self.shouldDisplayLinkedQuestions = linkedContent.isEmpty == false
        self.actionButtonTitle = actionButtonTitle
        self.interfaceOrientationStream = interfaceOrientationStream
        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hasBottomMargin = true
        title = .moreInformationReceivedNotificationTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.showVisual = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)

        internalView.buttonActionHandler = { [weak self] in
            self?.listener?.receivedNotificationActionButtonTapped()
        }

        linkedContentTableViewManager.selectedContentHandler = { [weak self] selectedContent in
            self?.listener?.receivedNotificationRequestRedirect(to: selectedContent)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldDisplayLinkedQuestions {
            internalView.tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }

        interfaceOrientationStream
            .isLandscape
            .subscribe { [weak self] isLandscape in
                self?.internalView.showVisual = !isLandscape
            }.disposed(by: disposeBag)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if shouldDisplayLinkedQuestions {
            internalView.tableView.removeObserver(self, forKeyPath: "contentSize")
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.internalView.tableView, keyPath == "contentSize" {
                internalView.updateTableViewHeight()
            }
        }
    }

    // MARK: - Private

    private weak var listener: ReceivedNotificationListener?
    private lazy var internalView: ReceivedNotificationView = ReceivedNotificationView(theme: theme,
                                                                                       linkedContentTableViewManager: linkedContentTableViewManager,
                                                                                       buttonTitle: actionButtonTitle)

    private let linkedContentTableViewManager: LinkedContentTableViewManager
    private let shouldDisplayLinkedQuestions: Bool
    private let actionButtonTitle: String?
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var disposeBag = DisposeBag()

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.receivedNotificationWantsDismissal(shouldDismissViewController: true)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.receivedNotificationWantsDismissal(shouldDismissViewController: false)
    }
}

private final class ReceivedNotificationView: View {

    lazy var tableView = LinkedContentTableView(manager: tableViewManager)

    var buttonActionHandler: (() -> ())? {
        get { infoView.actionHandler }
        set { infoView.actionHandler = newValue }
    }

    var showVisual: Bool = true {
        didSet {
            infoView.showHeader = showVisual
        }
    }

    // MARK: - Init

    init(theme: Theme, linkedContentTableViewManager: LinkedContentTableViewManager, buttonTitle: String?) {

        self.tableViewManager = linkedContentTableViewManager
        let config = InfoViewConfig(actionButtonTitle: buttonTitle ?? "",
                                    headerImage: .receivedNotificationHeader,
                                    showButtons: buttonTitle != nil)
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        exampleNotificationWrapperView.addSubview(examplePushNotificationImageView)
        exampleExposureWrapperView.addSubview(exampleCaption)
        exampleExposureWrapperView.addSubview(exampleExposureImageView)
        tableViewWrapperView.addSubview(tableView)

        infoView.addSections([
            notificationExplanation(),
            exampleNotificationWrapperView,
            content(),
            exampleExposureWrapperView,
            whatToDo(),
            otherReports(),
            tableViewWrapperView
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.bottom.equalToSuperview()
        }

        exampleCaption.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.top.equalToSuperview()
        }
        exampleExposureImageView.snp.makeConstraints { maker in
            let aspectRatio = exampleExposureImageView.image?.aspectRatio ?? 1

            maker.top.equalTo(exampleCaption.snp.bottom).offset(15)
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.equalTo(exampleExposureImageView.snp.width).dividedBy(aspectRatio)
            maker.bottom.equalToSuperview()
        }
        examplePushNotificationImageView.snp.makeConstraints { maker in
            let aspectRatio = examplePushNotificationImageView.image?.aspectRatio ?? 1

            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.equalTo(examplePushNotificationImageView.snp.width).dividedBy(aspectRatio)
            maker.top.bottom.equalToSuperview()
        }
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0).priority(.high)
        }
    }

    func updateTableViewHeight() {

        tableView.snp.updateConstraints { maker in
            maker.height.equalTo(tableView.contentSize.height).priority(.high)
        }
    }

    // MARK: - Private

    private func notificationExplanation() -> View {
        InfoSectionTextView(theme: theme,
                            title: .helpOtherWhatDoesReportSayTitle,
                            content: [attributedContentText(for: .helpReceivedNotificationMeaningDescription1)])
    }

    private func content() -> View {
        InfoSectionContentTextView(theme: theme, content: [attributedContentText(for: .helpReceivedNotificationMeaningDescription2)])
    }

    private func whatToDo() -> View {
        InfoSectionTextView(theme: theme,
                            title: .helpReceivedNotificationWhatToDoTitle,
                            content: [attributedContentText(for: .helpReceivedNotificationWhatToDoDescription)])
    }

    private func otherReports() -> View {
        InfoSectionTextView(theme: theme,
                            title: .helpReceivedNotificationOtherReportsTitle,
                            content: [attributedContentText(for: .helpReceivedNotificationOtherReportsDescription)])
    }

    private func attributedContentText(for string: String) -> NSAttributedString {
        NSAttributedString.makeFromHtml(text: string, font: theme.fonts.body, textColor: theme.colors.gray)
    }

    private let infoView: InfoView
    private lazy var tableViewWrapperView = View(theme: theme)
    private let tableViewManager: LinkedContentTableViewManager
    private lazy var exampleExposureWrapperView = View(theme: theme)
    private lazy var exampleNotificationWrapperView = View(theme: theme)

    private lazy var examplePushNotificationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .helpPushNotificationExample
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var exampleExposureImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .helpNotificationExample
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var exampleCaption: Label = {
        let label = Label()
        label.text = .helpReceivedNotificationExample
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = theme.colors.captionGray
        label.font = theme.fonts.bodyBold
        return label
    }()
}

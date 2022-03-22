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
protocol MessageViewControllable: ViewControllable {}

final class MessageViewController: ViewController, MessageViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: MessageListener,
         theme: Theme,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         dataController: ExposureDataControlling,
         messageManager: MessageManaging,
         applicationController: ApplicationControlling) {
        self.listener = listener
        self.interfaceOrientationStream = interfaceOrientationStream
        self.dataController = dataController
        self.messageManager = messageManager
        self.applicationController = applicationController

        self.treatmentPerspectiveMessage = messageManager.getLocalizedTreatmentPerspective()

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

        setThemeNavigationBar(withTitle: .contaminationChanceTitle)

        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = { [weak self] in

            guard let strongSelf = self else {
                return
            }

            guard let coronaTestURL = strongSelf.dataController.getStoredCoronaTestURL() else {
                strongSelf.logError("Unable to to retreive coronaTestURL from storage")
                return
            }

            guard let url = URL(string: coronaTestURL) else {
                strongSelf.logError("Unable to open \(coronaTestURL)")
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

        internalView.infoView.showHeader = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)

        interfaceOrientationStream
            .isLandscape
            .subscribe { [weak self] isLandscape in
                self?.internalView.infoView.showHeader = !isLandscape
            }.disposed(by: disposeBag)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.messageWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.messageWantsDismissal(shouldDismissViewController: true)
    }

    private lazy var internalView: MessageView = {
        MessageView(theme: self.theme, treatmentPerspectiveMessage: treatmentPerspectiveMessage, linkHandler: { [weak self] link in
            self?.openLinkInExternalBrowser(link)
        })
    }()

    private func openLinkInExternalBrowser(_ link: String) {
        var linkToOpen = link
        if !linkToOpen.starts(with: "https://") {
            linkToOpen = "https://" + link
        }
        guard let url = URL(string: linkToOpen) else {
            logError("Unable to create URL from string: \(linkToOpen)")
            return
        }
        applicationController.open(url)
    }

    private weak var listener: MessageListener?
    private let messageManager: MessageManaging
    private let treatmentPerspectiveMessage: LocalizedTreatmentPerspective
    private let dataController: ExposureDataControlling
    private var disposeBag = DisposeBag()
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private let applicationController: ApplicationControlling
}

private final class MessageView: View {

    // MARK: - Init

    init(theme: Theme, treatmentPerspectiveMessage: LocalizedTreatmentPerspective, linkHandler: @escaping ((String) -> ())) {
        let config = InfoViewConfig(actionButtonTitle: .messageButtonTitle,
                                    headerImage: .messageHeader,
                                    headerBackgroundViewColor: theme.colors.headerBackgroundRed,
                                    stickyButtons: true)
        self.infoView = InfoView(theme: theme, config: config, itemSpacing: 26)
        self.linkHandler = linkHandler
        self.treatmentPerspectiveMessage = treatmentPerspectiveMessage
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        let content = NSMutableAttributedString()

        treatmentPerspectiveMessage.paragraphs.forEach { paragraph in
            content.append(.makeFromHtml(text: paragraph.title, font: theme.fonts.title2, textColor: theme.colors.textPrimary, textAlignment: Localization.textAlignment))
            content.append(.init(string: "\n"))
            paragraph.body.forEach { attrString in
                content.append(attrString)
                content.append(.init(string: "\n"))
            }
        }

        let textView = InfoSectionTextView(theme: theme, content: content)
        textView.linkHandler = linkHandler

        infoView.addSections([textView])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.bottom.equalToSuperview()
        }
    }

    // MARK: - Private

    private let treatmentPerspectiveMessage: LocalizedTreatmentPerspective
    fileprivate let infoView: InfoView
    private let linkHandler: (String) -> ()
}

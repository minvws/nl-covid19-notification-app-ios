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
         messageManager: MessageManaging) {
        self.listener = listener
        self.interfaceOrientationStream = interfaceOrientationStream
        self.dataController = dataController
        self.messageManager = messageManager

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

            strongSelf.dataController
                .getAppointmentPhoneNumber()
                .subscribe { event in
                    var phoneNumber: String = .coronaTestExposedPhoneNumber

                    if case let .success(retrievedPhoneNumber) = event {
                        phoneNumber = retrievedPhoneNumber
                    }

                    // Because the current screen is only shown on exposed devices, we can use the phonenumber that is exclusively for exposed persons
                    let phoneNumberLink: String = .phoneNumberLink(from: phoneNumber)

                    if let url = URL(string: phoneNumberLink), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        strongSelf.logError("Unable to open \(phoneNumberLink)")
                    }
                }
                .disposed(by: strongSelf.disposeBag)
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
        MessageView(theme: self.theme, treatmentPerspectiveMessage: treatmentPerspectiveMessage)
    }()

    private weak var listener: MessageListener?
    private let messageManager: MessageManaging
    private let treatmentPerspectiveMessage: LocalizedTreatmentPerspective
    private let dataController: ExposureDataControlling
    private var disposeBag = DisposeBag()
    private let interfaceOrientationStream: InterfaceOrientationStreaming
}

private final class MessageView: View {

    // MARK: - Init

    init(theme: Theme, treatmentPerspectiveMessage: LocalizedTreatmentPerspective) {
        let config = InfoViewConfig(actionButtonTitle: .messageButtonTitle,
                                    headerImage: .messageHeader,
                                    headerBackgroundViewColor: theme.colors.headerBackgroundRed,
                                    stickyButtons: true)
        self.infoView = InfoView(theme: theme, config: config)
        self.treatmentPerspectiveMessage = treatmentPerspectiveMessage
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        let sections = treatmentPerspectiveMessage
            .paragraphs
            .map { InfoSectionTextView(theme: theme, title: $0.title, content: $0.body) }

        infoView.addSections(sections)

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
}

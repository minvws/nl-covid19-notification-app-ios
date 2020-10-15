/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import SnapKit
import UIKit

/// @mockable
protocol MessageViewControllable: ViewControllable {}

final class MessageViewController: ViewController, MessageViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: MessageListener, theme: Theme, exposureDate: Date, messageManager: MessageManaging) {
        self.listener = listener
        self.exposureDate = exposureDate
        self.messageManager = messageManager
        self.treatmentPerspectiveMessage = messageManager.getTreatmentPerspectiveMessage()

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

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = { [weak self] in
            if let url = URL(string: .coronaTestPhoneNumber), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                self?.logError("Unable to open \(String.coronaTestPhoneNumber)")
            }
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.messageWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    private func formattedExposureDate() -> String {
        let now = currentDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let dateString = dateFormatter.string(from: exposureDate)
        let days = now.days(sinceDate: exposureDate) ?? 0

        return "\(dateString) (\(String.statusNotifiedDaysAgo(days: days)))"
    }

    private func formattedTenDaysAfterExposure() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let tenDays: TimeInterval = 60 * 60 * 24 * 10
        let tenDaysAfterExposure = exposureDate.advanced(by: tenDays)

        return dateFormatter.string(from: tenDaysAfterExposure)
    }

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.messageWantsDismissal(shouldDismissViewController: true)
    }

    private lazy var internalView: MessageView = {
        MessageView(theme: self.theme, formattedExposureDate: formattedExposureDate(), formattedFutureDate: formattedTenDaysAfterExposure(), treatmentPerspectiveMessage: treatmentPerspectiveMessage)
    }()

    private let exposureDate: Date
    private weak var listener: MessageListener?
    private let messageManager: MessageManaging
    private let treatmentPerspectiveMessage: TreatmentPerspectiveMessage
}

private final class MessageView: View {

    fileprivate let infoView: InfoView
    private let formattedExposureDate: String
    private let formattedFutureDate: String

    // MARK: - Init

    init(theme: Theme, formattedExposureDate: String, formattedFutureDate: String, treatmentPerspectiveMessage: TreatmentPerspectiveMessage) {
        self.formattedExposureDate = formattedExposureDate
        self.formattedFutureDate = formattedFutureDate
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

        var sections: [View] = []

        treatmentPerspectiveMessage.paragraphs.forEach {
            sections.append(InfoSectionTextView(theme: theme,
                                                title: $0.title,
                                                content: [$0.body]))
        }
        infoView.addSections(sections)

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.edges.equalToSuperview()
        }
    }

    // MARK: - Private

    private let treatmentPerspectiveMessage: TreatmentPerspectiveMessage
}

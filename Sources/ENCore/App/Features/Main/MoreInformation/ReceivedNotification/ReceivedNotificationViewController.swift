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
protocol ReceivedNotificationViewControllable: ViewControllable {}

final class ReceivedNotificationViewController: ViewController, ReceivedNotificationViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: ReceivedNotificationListener, theme: Theme) {
        self.listener = listener

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

        internalView.contactButtonActionHandler = { [weak self] in
            if let url = URL(string: .coronaTestPhoneNumber), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                self?.logError("Unable to open \(String.coronaTestPhoneNumber)")
            }
        }
    }

    // MARK: - Private

    private weak var listener: ReceivedNotificationListener?
    private lazy var internalView: ReceivedNotificationView = ReceivedNotificationView(theme: self.theme)

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.receivedNotificationWantsDismissal(shouldDismissViewController: true)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.receivedNotificationWantsDismissal(shouldDismissViewController: false)
    }
}

private final class ReceivedNotificationView: View {

    var contactButtonActionHandler: (() -> ())? {
        get { infoView.actionHandler }
        set { infoView.actionHandler = newValue }
    }

    private let infoView: InfoView

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: .moreInformationReceivedNotificationButtonTitle,
                                    headerImage: .receivedNotificationHeader)
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()
        exampleWrapperView.addSubview(exampleImageView)
        exampleWrapperView.addSubview(exampleCaption)

        infoView.addSections([
            notificationExplanation(),
            howReportLooksLike(),
            exampleWrapperView,
            whatToDo(),
            otherReports()
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.bottom.leading.trailing.equalToSuperview()
        }

        exampleImageView.snp.makeConstraints { maker in
            let aspectRatio = exampleImageView.image?.aspectRatio ?? 1

            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.height.equalTo(exampleImageView.snp.width).dividedBy(aspectRatio)
        }

        exampleCaption.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(exampleImageView.snp.bottom).offset(24)
        }
    }

    // MARK: - Private

    private func notificationExplanation() -> View {
        InfoSectionTextView(theme: theme,
                            title: .helpReceivedNotificationMeaningTitle,
                            content: [String.helpReceivedNotificationMeaningDescription.attributed()])
    }

    private func howReportLooksLike() -> View {
        InfoSectionTextView(theme: theme,
                            title: .helpReceivedNotificationReportTitle,
                            content: [String.helpReceivedNotificationReportDescription.attributed()])
    }

    private func whatToDo() -> View {
        InfoSectionTextView(theme: theme,
                            title: .helpReceivedNotificationWhatToDoTitle,
                            content: [String.helpReceivedNotificationWhatToDoDescription.attributed()])
    }

    private func otherReports() -> View {
        InfoSectionTextView(theme: theme,
                            title: .helpReceivedNotificationOtherReportsTitle,
                            content: [String.helpReceivedNotificationOtherReportsDescription.attributed()])
    }

    private lazy var exampleWrapperView = View(theme: theme)

    private lazy var exampleImageView: UIImageView = {
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

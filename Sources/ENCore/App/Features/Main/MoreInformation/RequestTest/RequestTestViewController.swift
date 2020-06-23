/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import SnapKit
import UIKit

/// @mockable
protocol RequestTestViewControllable: ViewControllable {}

final class RequestTestViewController: ViewController, RequestTestViewControllable, UIAdaptivePresentationControllerDelegate {

    // MARK: - Init

    init(listener: RequestTestListener, theme: Theme) {
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

        title = Localization.string(for: "moreInformation.requestTest.title")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.contactButtonActionHandler = {
            let urlString = "tel://08001202"
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("🔥 Unable to open \(urlString)")
            }
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.requestTestWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    private weak var listener: RequestTestListener?
    private lazy var internalView: RequestTestView = RequestTestView(theme: self.theme)

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.requestTestWantsDismissal(shouldDismissViewController: true)
    }
}

private final class RequestTestView: View {

    var contactButtonActionHandler: (() -> ())? {
        get { infoView.actionHandler }
        set { infoView.actionHandler = newValue }
    }

    private let infoView: InfoView

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: Localization.string(for: "moreInformation.requestTest.button.title"),
                                    headerImage: Image.named("CoronatestHeader"))
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            receivedNotification(),
            complaints(),
            info()
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.bottom.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Private

    private func receivedNotification() -> View {
        // TODO: Bold Phone Number
        InfoSectionTextView(theme: theme,
                            title: Localization.string(for: "moreInformation.requestTest.receivedNotification.title"),
                            content: Localization.attributedString(for: "moreInformation.requestTest.receivedNotification.content"))
    }

    private func complaints() -> View {
        let list = [
            Localization.string(for: "moreInformation.complaints.item1"),
            Localization.string(for: "moreInformation.complaints.item2"),
            Localization.string(for: "moreInformation.complaints.item3"),
            Localization.string(for: "moreInformation.complaints.item4")
        ]
        let bulletList = NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body)
        let content = Localization.attributedString(for: "moreInformation.complaints.content")

        let string = NSMutableAttributedString()
        string.append(bulletList)
        string.append(content)
        return InfoSectionTextView(theme: theme,
                                   title: Localization.string(for: "moreInformatio.complaints.title"),
                                   content: string)
    }

    private func info() -> View {
        let string = Localization.attributedString(for: "moreInformation.info.title")
        return InfoSectionCalloutView(theme: theme, content: string)
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import SafariServices
import SnapKit
import UIKit

/// @mockable
protocol RequestTestViewControllable: ViewControllable {}

final class RequestTestViewController: ViewController, RequestTestViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: RequestTestListener,
         theme: Theme,
         interfaceOrientationStream: InterfaceOrientationStreaming) {
        self.listener = listener
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
        title = .moreInformationRequestTestTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.showVisual = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)

        internalView.linkButtonActionHandler = { [weak self] in

            let testWebsiteUrl: String = Localization.isUsingDutchLanguage ? .coronaTestWebUrl : .coronaTestWebUrlInternational

            guard let url = URL(string: testWebsiteUrl) else {
                self?.logError("Unable to open \(testWebsiteUrl)")
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        internalView.phoneButtonActionHandler = { [weak self] in
            if let url = URL(string: .coronaTestPhoneNumber), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                self?.logError("Unable to open \(String.coronaTestPhoneNumber)")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        interfaceOrientationStreamCancellable = interfaceOrientationStream
            .isLandscape
            .sink(receiveValue: { [weak self] isLandscape in
                self?.internalView.showVisual = !isLandscape
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        interfaceOrientationStreamCancellable = nil
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.requestTestWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    private weak var listener: RequestTestListener?
    private lazy var internalView: RequestTestView = RequestTestView(theme: self.theme)
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var interfaceOrientationStreamCancellable: AnyCancellable?

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.requestTestWantsDismissal(shouldDismissViewController: true)
    }
}

private final class RequestTestView: View {

    var phoneButtonActionHandler: (() -> ())? {
        get { infoView.secondaryActionHandler }
        set { infoView.secondaryActionHandler = newValue }
    }
    var linkButtonActionHandler: (() -> ())? {
        get { infoView.actionHandler }
        set { infoView.actionHandler = newValue }
    }

    var showVisual: Bool = true {
        didSet {
            infoView.showHeader = showVisual
        }
    }

    private let infoView: InfoView

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: .moreInformationRequestTestLink,
                                    secondaryButtonTitle: .moreInformationRequestTestPhone,
                                    headerImage: .coronatestHeader,
                                    stickyButtons: true)
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            receivedNotification(),
            complaints(),
            requestTest()
        ])

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

    private func receivedNotification() -> View {
        InfoSectionTextView(theme: theme,
                            title: .moreInformationRequestTestReceivedNotificationTitle,
                            content: [NSAttributedString.makeFromHtml(text: .moreInformationRequestTestReceivedNotificationContent, font: theme.fonts.body, textColor: theme.colors.gray)])
    }

    private func complaints() -> View {
        let list: [String] = [
            .moreInformationComplaintsItem1,
            .moreInformationComplaintsItem2,
            .moreInformationComplaintsItem3,
            .moreInformationComplaintsItem4,
            .moreInformationComplaintsItem5
        ]
        var string = NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body, useTrailingNewLine: false)
        string.append(NSAttributedString(string: " ")) // Should be a space to ensure the correct line spacing
        string.append(NSAttributedString(string: .moreInformationRequestTestComplaints))

        return InfoSectionTextView(theme: theme,
                                   title: .moreInformationComplaintsTitle,
                                   content: string)
    }

    private func requestTest() -> View {
        InfoSectionTextView(theme: theme,
                            title: .moreInformationRequestTestTitle,
                            content: [String.moreInformationInfoTitle.attributed()])
    }
}

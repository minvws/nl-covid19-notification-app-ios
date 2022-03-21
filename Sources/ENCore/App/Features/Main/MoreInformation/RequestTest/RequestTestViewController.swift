/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import RxSwift
import SafariServices
import SnapKit
import UIKit

/// @mockable
protocol RequestTestViewControllable: ViewControllable {}

final class RequestTestViewController: ViewController, RequestTestViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: RequestTestListener,
         theme: Theme,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         exposureStateStream: ExposureStateStreaming,
         dataController: ExposureDataControlling) {
        self.listener = listener
        self.interfaceOrientationStream = interfaceOrientationStream
        self.dataController = dataController

        isExposed = false
        if case .notified = exposureStateStream.currentExposureState.notifiedState {
            isExposed = true
        }

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
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton(sender:)))

        internalView.showVisual = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)

        internalView.linkButtonActionHandler = { [weak self] in

//            let testWebsiteUrl: String = Localization.isUsingDutchLanguage ? .coronaTestWebUrl : .coronaTestWebUrlInternational

            guard let coronaTestURL = self?.dataController.getStoredCoronaTestURL() else {
                self?.logError("Unable to to retreive coronaTestURL from storage")
                return
            }

            guard let url = URL(string: coronaTestURL) else {
                self?.logError("Unable to open \(coronaTestURL)")
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        interfaceOrientationStream
            .isLandscape
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] isLandscape in
                self?.internalView.showVisual = !isLandscape
            }.disposed(by: disposeBag)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.requestTestWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    private weak var listener: RequestTestListener?

    private var isExposed: Bool

    private lazy var internalView = RequestTestView(theme: self.theme)

    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private let dataController: ExposureDataControlling
    private var disposeBag = DisposeBag()

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.requestTestWantsDismissal(shouldDismissViewController: true)
    }
}

private final class RequestTestView: View {

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
                                    headerImage: .coronatestHeader,
                                    stickyButtons: true)
        self.infoView = InfoView(theme: theme, config: config, itemSpacing: 24)
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
                            content: NSAttributedString.makeFromHtml(text: .moreInformationRequestTestReceivedNotificationContent, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.textAlignment))
    }

    private func complaints() -> View {
        let list: [String] = [
            .moreInformationComplaintsItem1,
            .moreInformationComplaintsItem2,
            .moreInformationComplaintsItem3,
            .moreInformationComplaintsItem4,
            .moreInformationComplaintsItem5
        ]

        let content = NSMutableAttributedString()
        content.append(NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body, textAlignment: Localization.textAlignment))
        content.append(.makeFromHtml(text: .moreInformationRequestTestComplaints, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.textAlignment))

        return InfoSectionTextView(theme: theme,
                                   title: .moreInformationComplaintsTitle,
                                   content: content)
    }

    private func requestTest() -> View {
        InfoSectionTextView(theme: theme,
                            title: .moreInformationRequestTestTitle,
                            content: .makeFromHtml(text: .moreInformationInfoTitle, font: theme.fonts.body, textColor: theme.colors.textSecondary, textAlignment: Localization.textAlignment))
    }
}

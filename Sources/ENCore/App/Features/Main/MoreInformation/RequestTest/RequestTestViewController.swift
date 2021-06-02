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
        if case .notified = exposureStateStream.currentExposureState?.notifiedState {
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

            let testWebsiteUrl: String = Localization.isUsingDutchLanguage ? .coronaTestWebUrl : .coronaTestWebUrlInternational

            guard let url = URL(string: testWebsiteUrl) else {
                self?.logError("Unable to open \(testWebsiteUrl)")
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        internalView.phoneButtonActionHandler = { [weak self] in
            guard let strongSelf = self else { return }
            let phoneNumberLink: String = .phoneNumberLink(from: strongSelf.testPhoneNumber)
            if let url = URL(string: phoneNumberLink), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                strongSelf.logError("Unable to open \(phoneNumberLink)")
            }
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

        dataController
            .getAppointmentPhoneNumber()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { exposedPhoneNumber in
                self.testPhoneNumber = self.isExposed ? exposedPhoneNumber : .coronaTestPhoneNumber
            }, onFailure: { _ in
                self.testPhoneNumber = self.isExposed ? .coronaTestExposedPhoneNumber : .coronaTestPhoneNumber
            })
            .disposed(by: disposeBag)
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

    private var testPhoneNumber: String = "" {
        didSet {
            internalView.testPhoneNumber = testPhoneNumber
        }
    }

    private var isExposed: Bool

    private lazy var internalView = RequestTestView(theme: self.theme, testPhoneNumber: testPhoneNumber)

    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private let dataController: ExposureDataControlling
    private var disposeBag = DisposeBag()

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

    var testPhoneNumber: String {
        didSet {
            // This string is manually formatted to ensure the phone number is always displayed left-to-right.
            // \u{202A} starts left-to-right text, \u{202C} pops directional formatting
            formattedPhoneNumber = String(format: .moreInformationRequestTestPhone, arguments: ["\u{202A}\(testPhoneNumber)\u{202C}"])
            infoView.secondaryButton?.title = formattedPhoneNumber
        }
    }

    private var formattedPhoneNumber: String = ""
    private let infoView: InfoView

    // MARK: - Init

    init(theme: Theme, testPhoneNumber: String) {

        self.testPhoneNumber = testPhoneNumber
        let callButtonTitle = formattedPhoneNumber

        let config = InfoViewConfig(actionButtonTitle: .moreInformationRequestTestLink,
                                    secondaryButtonTitle: callButtonTitle,
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
        var string = NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body)
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

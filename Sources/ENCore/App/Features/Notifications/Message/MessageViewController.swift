/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import SnapKit
import UIKit

/// @mockable
protocol MessageViewControllable: ViewControllable {}

final class MessageViewController: ViewController, MessageViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: MessageListener,
         theme: Theme,
         exposureDate: Date,
         interfaceOrientationStream: InterfaceOrientationStreaming) {
        self.listener = listener
        self.exposureDate = exposureDate
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

        internalView.infoView.showHeader = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)
        interfaceOrientationStream
            .isLandscape
            .sink { [weak self] isLandscape in
                self?.internalView.infoView.showHeader = !isLandscape
            }
            .store(in: &disposeBag)
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
        MessageView(theme: self.theme, formattedExposureDate: formattedExposureDate(), formattedFutureDate: formattedTenDaysAfterExposure())
    }()

    private let exposureDate: Date
    private weak var listener: MessageListener?
    private var disposeBag = Set<AnyCancellable>()
    private let interfaceOrientationStream: InterfaceOrientationStreaming
}

private final class MessageView: View {

    fileprivate let infoView: InfoView
    private let formattedExposureDate: String
    private let formattedFutureDate: String

    // MARK: - Init

    init(theme: Theme, formattedExposureDate: String, formattedFutureDate: String) {
        self.formattedExposureDate = formattedExposureDate
        self.formattedFutureDate = formattedFutureDate
        let config = InfoViewConfig(actionButtonTitle: .messageButtonTitle,
                                    headerImage: .messageHeader,
                                    headerBackgroundViewColor: theme.colors.headerBackgroundRed,
                                    stickyButtons: true)
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            nearSomeoneWithCorona(),
            whatCanYouDo(),
            stayHome(),
            visitors(),
            medicalHelp(),
            after(),
            complaints()
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

    private func nearSomeoneWithCorona() -> View {
        InfoSectionTextView(theme: theme,
                            title: .contaminationChanceNearSomeoneWithCoronaTitle,
                            content: [NSAttributedString.makeFromHtml(text: .contaminationChanceNearSomeoneWithCoronaDescription(formattedExposureDate),
                                                                      font: theme.fonts.body,
                                                                      textColor: theme.colors.gray)])
    }

    private func whatCanYouDo() -> View {
        let list: [String] = [
            .contaminationChanceWhatToDoStep1(formattedFutureDate),
            .contaminationChanceWhatToDoStep2(formattedFutureDate),
            .contaminationChanceWhatToDoStep3
        ]

        var content = NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body)
        content.append(NSAttributedString.makeFromHtml(text: .contaminationChanceWhatToDoDescription,
                                                       font: theme.fonts.body,
                                                       textColor: theme.colors.gray))

        return InfoSectionTextView(theme: theme,
                                   title: .contaminationChanceWhatToDoTitle,
                                   content: content)
    }

    private func stayHome() -> View {
        let list: [String] = [
            .contaminationChanceStayHomeStep1,
            .contaminationChanceStayHomeStep2,
            .contaminationChanceStayHomeStep3
        ]
        let bulletList = NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body)

        return InfoSectionTextView(theme: theme,
                                   title: .contaminationChanceStayHomeTitle(formattedFutureDate),
                                   content: bulletList)
    }

    private func visitors() -> View {
        let list: [String] = [.contaminationChanceVisitorsStep1]
        let bulletList = NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body)

        return InfoSectionTextView(theme: theme,
                                   title: .contaminationChanceVisitorsTitle,
                                   content: bulletList)
    }

    private func medicalHelp() -> View {
        let list: [String] = [
            .contaminationChanceMedicalHelpStep1,
            .contaminationChanceMedicalHelpStep2
        ]
        let bulletList = NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body)

        return InfoSectionTextView(theme: theme,
                                   title: .contaminationChanceMedicalHelpTitle,
                                   content: bulletList)
    }

    private func after() -> View {
        InfoSectionTextView(theme: theme,
                            title: .contaminationChanceAfterTitle(formattedFutureDate),
                            content: [String.contaminationChanceAfterDescription(formattedFutureDate).attributed()])
    }

    private func complaints() -> View {
        let list: [String] = [
            .moreInformationComplaintsItem1,
            .moreInformationComplaintsItem2,
            .moreInformationComplaintsItem3,
            .moreInformationComplaintsItem4,
            .moreInformationComplaintsItem5
        ]
        let bulletList = NSAttributedString.bulletList(list, theme: theme, font: theme.fonts.body)

        return InfoSectionTextView(theme: theme,
                                   title: .contaminationChanceComplaintsTitle,
                                   content: bulletList)
    }
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit
import WebKit

final class AppInformationViewController: ViewController {

    init(listener: AppInformationListener, theme: Theme) {
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
        navigationItem.rightBarButtonItem = self.navigationController?.navigationItem.rightBarButtonItem

        internalView.technicalInformationButton.action = { [weak self] in
            self?.listener?.appInformationRequestsToTechinicalInformation()
        }
    }

    // MARK: - Private

    private weak var listener: AppInformationListener?
    private lazy var internalView: AppInformationView = AppInformationView(theme: self.theme)
}

private final class AppInformationView: View {

    private lazy var scrollableStackView = ScrollableStackView(theme: theme)

    override func build() {
        super.build()

        buttonWrapperView.addSubview(technicalInformationButton)
        technicalInformationButton.backgroundColor = theme.colors.lightOrange

        addSubview(scrollableStackView)

        scrollableStackView.attributedTitle = String.helpWhatAppDoesTitle.attributed()
        scrollableStackView.addSections([
            protectView,
            notifyView,
            bluetoothView,
            cycleExampleView,
            trainExampleView,
            buttonWrapperView
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollableStackView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }

        technicalInformationButton.snp.makeConstraints { maker in
            maker.top.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }

    lazy var technicalInformationButton = CardButton(title: .aboutTechnicalInformationTitle,
                                                     subtitle: .aboutTechnicalInformationDescription,
                                                     image: .aboutTechnicalInformation,
                                                     theme: theme)

    private lazy var protectView = InformationCardView(theme: theme,
                                                       image: UIImage.appInformationProtect,
                                                       title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesProtectTitle, font: theme.fonts.title2, textColor: .black),
                                                       message: String.helpWhatAppDoesProtectDescription.attributed())

    private lazy var notifyView = InformationCardView(theme: theme,
                                                      image: UIImage.appInformationNotify,
                                                      title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesNotifyTitle, font: theme.fonts.title2, textColor: .black),
                                                      message: String.helpWhatAppDoesNotifyDescription.attributed())

    private lazy var bluetoothView = InformationCardView(theme: theme,
                                                         image: UIImage.appInformationBluetooth,
                                                         title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesBluetoothTitle, font: theme.fonts.title2, textColor: .black),
                                                         message: String.helpWhatAppDoesBluetoothDescription.attributed())

    private lazy var cycleExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.appInformationExampleCycle,
                                                            pretitle: String.example.attributed(),
                                                            title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesExampleCycleTitle, font: theme.fonts.title2, textColor: .black),
                                                            message: String.helpWhatAppDoesExampleCycleDescription.attributed())

    private lazy var trainExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.appInformationExampleTrain,
                                                            pretitle: String.example.attributed(),
                                                            title: NSAttributedString.makeFromHtml(text: String.helpWhatAppDoesExampleTrainTitle, font: theme.fonts.title2, textColor: .black),
                                                            message: String.helpWhatAppDoesExampleTrainDescription.attributed())

    private lazy var buttonWrapperView = View(theme: theme)
}

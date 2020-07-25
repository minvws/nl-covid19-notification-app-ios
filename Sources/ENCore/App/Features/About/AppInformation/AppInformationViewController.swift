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
    }

    // MARK: - Private

    private weak var listener: AppInformationListener?
    private lazy var internalView: AppInformationView = AppInformationView(theme: self.theme)
}

private final class AppInformationView: View {

    private lazy var scrollableStackView = ScrollableStackView(theme: theme)

    override func build() {
        super.build()

        addSubview(scrollableStackView)

        scrollableStackView.attributedTitle = String.helpWhatAppDoesTitle.attributed()
        scrollableStackView.addSections([
            protectView,
            notifyView,
            bluetoothView,
            cycleExampleView,
            trainExampleView
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollableStackView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    private lazy var protectView = InformationCardView(theme: theme,
                                                       image: UIImage.appInformationProtect,
                                                       title: String.helpWhatAppDoesProtectTitle.attributed(),
                                                       message: String.helpWhatAppDoesProtectDescription.attributed())

    private lazy var notifyView = InformationCardView(theme: theme,
                                                      image: UIImage.appInformationNotify,
                                                      title: String.helpWhatAppDoesNotifyTitle.attributed(),
                                                      message: String.helpWhatAppDoesNotifyDescription.attributed())

    private lazy var bluetoothView = InformationCardView(theme: theme,
                                                         image: UIImage.appInformationBluetooth,
                                                         title: String.helpWhatAppDoesBluetoothTitle.attributed(),
                                                         message: String.helpWhatAppDoesBluetoothDescription.attributed())

    private lazy var cycleExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.appInformationExampleCycle,
                                                            pretitle: String.example.attributed(),
                                                            title: String.helpWhatAppDoesExampleCycleTitle.attributed(),
                                                            message: String.helpWhatAppDoesExampleCycleDescription.attributed())

    private lazy var trainExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.appInformationExampleTrain,
                                                            pretitle: String.example.attributed(),
                                                            title: String.helpWhatAppDoesExampleTrainTitle.attributed(),
                                                            message: String.helpWhatAppDoesExampleTrainDescription.attributed())
}

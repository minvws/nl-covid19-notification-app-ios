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
        self.view.backgroundColor = .yellow
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

    private let scrollView = UIScrollView(frame: .zero)
    private let stackView = UIStackView(frame: .zero)

    override func build() {
        super.build()

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 40
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        scrollView.addSubview(stackView)

        addSections([protectView, notifyView, bluetoothView, cycleExampleView, trainExampleView])
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }

        stackView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.bottom.leading.trailing.width.equalTo(scrollView)
        }
    }

    // MARK: - Private

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
                                                            title: String.helpWhatAppDoesExampleCycleTitle.attributed(),
                                                            message: String.helpWhatAppDoesExampleCycleDescription.attributed())

    private lazy var trainExampleView = InformationCardView(theme: theme,
                                                            image: UIImage.appInformationExampleTrain,
                                                            title: String.helpWhatAppDoesExampleTrainTitle.attributed(),
                                                            message: String.helpWhatAppDoesExampleTrainDescription.attributed())

    private func addSections(_ views: [UIView]) {
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }
}

private class InformationCardView: View {
    private let imageView: UIImageView
    private let titleLabel: Label
    private let messageLabel: Label

    init(theme: Theme, image: UIImage?, title: NSAttributedString, message: NSAttributedString) {
        self.titleLabel = Label(frame: .zero)
        self.messageLabel = Label(frame: .zero)
        self.imageView = UIImageView(image: image)
        super.init(theme: theme)

        titleLabel.attributedText = title
        titleLabel.font = theme.fonts.headline

        messageLabel.attributedText = message
        messageLabel.font = theme.fonts.body
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        imageView.contentMode = .scaleAspectFit
        titleLabel.numberOfLines = 0
        messageLabel.numberOfLines = 0

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        var imageAspectRatio: CGFloat = 0.0

        if let width = imageView.image?.size.width, let height = imageView.image?.size.height, width > 0, height > 0 {
            imageAspectRatio = height / width
        }

        imageView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(snp.width).multipliedBy(imageAspectRatio)
        }

        titleLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(imageView.snp.bottom).offset(16)
            maker.leading.trailing.equalToSuperview().inset(16)
        }

        messageLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalToSuperview().inset(16)

            constrainToSuperViewWithBottomMargin(maker: maker)
        }
    }
}

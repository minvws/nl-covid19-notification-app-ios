/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import SnapKit
import UIKit

/// @mockable
protocol StatusRouting: Routing {}

final class StatusViewController: ViewController, StatusViewControllable {

    // MARK: - StatusViewControllable

    weak var router: StatusRouting?

    private let exposureStateStream: ExposureStateStreaming
    private weak var listener: StatusListener?
    private weak var topAnchor: NSLayoutYAxisAnchor?

    private var exposureStateStreamCancellable: AnyCancellable?

    init(exposureStateStream: ExposureStateStreaming,
         listener: StatusListener,
         theme: Theme,
         topAnchor: NSLayoutYAxisAnchor?) {
        self.exposureStateStream = exposureStateStream
        self.listener = listener
        self.topAnchor = topAnchor

        super.init(theme: theme)
    }

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = statusView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        statusView.listener = listener
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        // Ties the top anchor of the view to the top anchor of the main view (outside of the scroll view)
        // to make the view stretch while rubber banding
        if let topAnchor = topAnchor {
            statusView.stretchGuide.topAnchor.constraint(equalTo: topAnchor)
                .withPriority(.defaultHigh - 100)
                .isActive = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        exposureStateStreamCancellable = exposureStateStream.exposureState.sink { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch (status.activeState, status.notifiedState) {
            case (.active, .notNotified):
                strongSelf.statusView.update(with: .activeWithNotNotified)
            case let (.active, .notified(date)):
                strongSelf.statusView.update(with: .activeWithNotified(date: date))
            case let (.inactive(_), .notified(date)):
                strongSelf.statusView.update(with: StatusViewModel.activeWithNotified(date: date).with(card: StatusCardViewModel.inactive))
            case (.inactive(_), .notNotified):
                strongSelf.statusView.update(with: .inactiveWithNotNotified)
            case let (.authorizationDenied, .notified(date)):
                strongSelf.statusView.update(with: StatusViewModel.inactiveWithNotified(date: date).with(card: StatusCardViewModel.inactive))
            case (.authorizationDenied, .notNotified):
                strongSelf.statusView.update(with: .inactiveWithNotNotified)
            case let (.notAuthorized, .notified(date)):
                strongSelf.statusView.update(with: StatusViewModel.inactiveWithNotified(date: date).with(card: StatusCardViewModel.inactive))
            case (.notAuthorized, .notNotified):
                strongSelf.statusView.update(with: .inactiveWithNotNotified)
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)

        exposureStateStreamCancellable = nil
    }

    // MARK: - Private

    private lazy var statusView: StatusView = StatusView(theme: self.theme)
}

private final class StatusView: View {

    fileprivate weak var listener: StatusListener? {
        didSet { cardView.listener = listener }
    }

    fileprivate let stretchGuide = UILayoutGuide() // grows larger while stretching, grows all visible elements
    private let contentStretchGuide = UILayoutGuide() // grows larger while stretching, used to center the content

    private let contentContainer = UIStackView()
    private let textContainer = UIStackView()
    private let buttonContainer = UIStackView()
    private lazy var cardView: StatusCardView = {
        return StatusCardView(theme: self.theme)
    }()
    private lazy var iconView: EmitterStatusIconView = {
        EmitterStatusIconView(theme: self.theme)
    }()

    private let testingContainer = UIView(frame: .zero)
    private let testingTitleLabel = Label()

    private let titleLabel = Label()
    private let descriptionLabel = Label()

    private let gradientLayer = CAGradientLayer()
    private let cloudsImageView = UIImageView()
    private let sceneImageView = UIImageView()

    private var containerToSceneVerticalConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    // MARK: - Overrides

    override func build() {
        super.build()

        cloudsImageView.image = Image.named("StatusClouds")

        sceneImageView.contentMode = .scaleAspectFit
        sceneImageView.image = Image.named("StatusScene")

        contentContainer.axis = .vertical
        contentContainer.spacing = 32
        contentContainer.alignment = .center

        testingTitleLabel.font = theme.fonts.subhead
        testingTitleLabel.textColor = .white
        testingTitleLabel.text = "Dit is een test versie"

        testingContainer.backgroundColor = .black
        testingContainer.layer.cornerRadius = 16
        testingContainer.layer.masksToBounds = true

        textContainer.axis = .vertical
        textContainer.spacing = 16

        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = theme.fonts.title2
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.font = theme.fonts.body
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        buttonContainer.axis = .vertical
        buttonContainer.spacing = 16

        layer.addSublayer(gradientLayer)
        testingContainer.addSubview(testingTitleLabel)
        textContainer.addArrangedSubview(titleLabel)
        textContainer.addArrangedSubview(descriptionLabel)
        contentContainer.addArrangedSubview(testingContainer)
        contentContainer.addArrangedSubview(iconView)
        contentContainer.addArrangedSubview(textContainer)
        contentContainer.addArrangedSubview(buttonContainer)
        contentContainer.addArrangedSubview(cardView)
        addSubview(cloudsImageView)
        addSubview(sceneImageView)
        addSubview(contentContainer)
        addLayoutGuide(contentStretchGuide)
        addLayoutGuide(stretchGuide)
    }

    override func setupConstraints() {
        super.setupConstraints()

        cloudsImageView.translatesAutoresizingMaskIntoConstraints = false
        sceneImageView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        containerToSceneVerticalConstraint = sceneImageView.topAnchor.constraint(greaterThanOrEqualTo: contentStretchGuide.bottomAnchor)
        heightConstraint = heightAnchor.constraint(equalToConstant: 0).withPriority(.defaultHigh + 100)

        let sceneImageAspectRatio = sceneImageView.image.map { $0.size.width / $0.size.height } ?? 1

        cloudsImageView.snp.makeConstraints { maker in
            maker.centerY.equalTo(iconView.snp.centerY)
            maker.leading.trailing.equalTo(stretchGuide)
        }
        sceneImageView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalTo(stretchGuide)
            maker.width.equalTo(sceneImageView.snp.height).multipliedBy(sceneImageAspectRatio)
        }
        testingTitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.bottom.equalToSuperview().inset(6)
        }
        stretchGuide.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(contentStretchGuide).inset(-24)
            maker.top.equalTo(contentStretchGuide).inset(-70)
            maker.bottom.greaterThanOrEqualTo(contentStretchGuide.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalToSuperview().priority(.low)
        }
        contentStretchGuide.snp.makeConstraints { maker in
            maker.leading.trailing.centerY.equalTo(contentContainer)
            maker.height.greaterThanOrEqualTo(contentContainer.snp.height)
            maker.bottom.equalTo(stretchGuide.snp.bottom).priority(.high)
        }
        iconView.snp.makeConstraints { maker in
            maker.width.height.equalTo(48)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = stretchGuide.layoutFrame
        CATransaction.commit()

        evaluateHeight()

        let height = testingContainer.frame.height
        let cornerRadius = ceil(height / 2)
        if cornerRadius != testingContainer.layer.cornerRadius {
            testingContainer.layer.cornerRadius = cornerRadius
        }
    }

    // MARK: - Internal

    func update(with viewModel: StatusViewModel) {
        iconView.update(with: viewModel.icon)

        titleLabel.attributedText = viewModel.title
        descriptionLabel.attributedText = viewModel.description

        buttonContainer.subviews.forEach { $0.removeFromSuperview() }
        for buttonModel in viewModel.buttons {
            let button = Button(title: buttonModel.title, theme: theme)
            button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
            button.style = buttonModel.style
            button.rounded = true
            button.action = { [weak self] in
                self?.listener?.handleButtonAction(buttonModel.action)
            }
            buttonContainer.addArrangedSubview(button)
        }
        buttonContainer.isHidden = viewModel.buttons.isEmpty

        if let cardViewModel = viewModel.card {
            cardView.update(with: cardViewModel)
            cardView.isHidden = false
        } else {
            cardView.isHidden = true
        }

        gradientLayer.colors = [theme.colors[keyPath: viewModel.gradientColor].cgColor, UIColor.white.withAlphaComponent(0).cgColor]

        sceneImageView.isHidden = !viewModel.showScene
        containerToSceneVerticalConstraint?.isActive = viewModel.showScene

        evaluateHeight()
    }

    // MARK: - Private

    /// Calculates the desired height for the current content
    /// This is required for stretching
    private func evaluateHeight() {
        guard bounds.width > 0 else { return }

        heightConstraint?.isActive = false
        let size = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        heightConstraint?.constant = size.height
        heightConstraint?.isActive = true
    }
}

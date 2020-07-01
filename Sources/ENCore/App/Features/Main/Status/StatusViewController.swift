/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
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
    fileprivate let contentStretchGuide = UILayoutGuide() // grows larger while stretching, used to center the content

    fileprivate let contentContainer = UIStackView()
    fileprivate let textContainer = UIStackView()
    fileprivate let buttonContainer = UIStackView()
    fileprivate lazy var cardView: StatusCardView = {
        return StatusCardView(theme: self.theme)
    }()
    fileprivate lazy var iconView: EmitterStatusIconView = {
        EmitterStatusIconView(theme: self.theme)
    }()

    fileprivate let titleLabel = Label()
    fileprivate let descriptionLabel = Label()

    fileprivate let gradientLayer = CAGradientLayer()
    fileprivate let cloudsImageView = UIImageView()
    fileprivate let sceneImageView = UIImageView()

    fileprivate var containerToSceneVerticalConstraint: NSLayoutConstraint?
    fileprivate var heightConstraint: NSLayoutConstraint?

    override func build() {
        super.build()

        // background
        layer.addSublayer(gradientLayer)

        cloudsImageView.image = Image.named("StatusClouds")
        addSubview(cloudsImageView)

        sceneImageView.contentMode = .scaleAspectFit
        sceneImageView.image = Image.named("StatusScene")
        addSubview(sceneImageView)

        // container
        contentContainer.axis = .vertical
        contentContainer.spacing = 24
        contentContainer.alignment = .center

        // iconView
        contentContainer.addArrangedSubview(iconView)

        // textContainer
        textContainer.axis = .vertical
        textContainer.spacing = 16
        //   titleLabel
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = theme.fonts.title2
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        textContainer.addArrangedSubview(titleLabel)
        //   descriptionLabel
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.font = theme.fonts.body
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        textContainer.addArrangedSubview(descriptionLabel)

        contentContainer.addArrangedSubview(textContainer)

        // buttonContainer
        buttonContainer.axis = .vertical
        buttonContainer.spacing = 16
        contentContainer.addArrangedSubview(buttonContainer)

        // cardView
        contentContainer.addArrangedSubview(cardView)

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
        self.heightConstraint = heightAnchor.constraint(equalToConstant: 0).withPriority(.defaultHigh + 100)

        let sceneImageAspectRatio = sceneImageView.image.map { $0.size.width / $0.size.height } ?? 1

        NSLayoutConstraint.activate([
            cloudsImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            cloudsImageView.leadingAnchor.constraint(equalTo: stretchGuide.leadingAnchor),
            cloudsImageView.trailingAnchor.constraint(equalTo: stretchGuide.trailingAnchor),

            sceneImageView.leadingAnchor.constraint(equalTo: stretchGuide.leadingAnchor),
            sceneImageView.trailingAnchor.constraint(equalTo: stretchGuide.trailingAnchor),
            sceneImageView.bottomAnchor.constraint(equalTo: stretchGuide.bottomAnchor),
            sceneImageView.widthAnchor.constraint(equalTo: sceneImageView.heightAnchor, multiplier: sceneImageAspectRatio),

            stretchGuide.leadingAnchor.constraint(equalTo: contentStretchGuide.leadingAnchor, constant: -24),
            stretchGuide.trailingAnchor.constraint(equalTo: contentStretchGuide.trailingAnchor, constant: 24),
            stretchGuide.topAnchor.constraint(equalTo: contentStretchGuide.topAnchor, constant: -70),
            stretchGuide.bottomAnchor.constraint(greaterThanOrEqualTo: contentStretchGuide.bottomAnchor),

            contentStretchGuide.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            contentStretchGuide.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            contentStretchGuide.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            contentStretchGuide.heightAnchor.constraint(greaterThanOrEqualTo: contentContainer.heightAnchor),
            contentStretchGuide.bottomAnchor.constraint(equalTo: stretchGuide.bottomAnchor).withPriority(.defaultHigh),

            stretchGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            stretchGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
            stretchGuide.topAnchor.constraint(equalTo: topAnchor).withPriority(.defaultLow),
            stretchGuide.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = stretchGuide.layoutFrame
        CATransaction.commit()

        evaluateHeight()
    }

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

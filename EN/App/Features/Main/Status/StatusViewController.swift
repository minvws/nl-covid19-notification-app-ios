/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit
import Combine

/// @mockable
protocol StatusRouting: Routing {
    
}

final class StatusViewController: ViewController, StatusViewControllable {
    
    // MARK: - StatusViewControllable

    weak var router: StatusRouting?

    private var exposureStateStream: ExposureStateStreaming
    private weak var listener: StatusListener?
    private weak var topAnchor: NSLayoutYAxisAnchor?

    private var exposureStateStreamCancellable: AnyCancellable?

    init(exposureStateStream: ExposureStateStreaming, listener: StatusListener, topAnchor: NSLayoutYAxisAnchor?) {
        self.exposureStateStream = exposureStateStream
        self.listener = listener
        self.topAnchor = topAnchor

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        self.view = statusView
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        // Ties the top anchor of the view to the top anchor of the main view (outside of the scroll view)
        // to make the view stretch while rubber banding
        if let topAnchor = topAnchor {
            statusView.stretchGuide.topAnchor.constraint(equalTo: topAnchor)
                .withPriority(.defaultHigh-100)
                .isActive = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // TODO: remove
        statusView.update(with: .active)

        exposureStateStreamCancellable = exposureStateStream.exposureState.sink { [weak self] status in
            switch (status.activeState, status.notified) {
            case (.active, false):
                self?.statusView.update(with: .active)
            case (.active, true):
                self?.statusView.update(with: .notified)
            case (.inactive(_), true):
                self?.statusView.update(with: StatusViewModel.notified.with(card: StatusCardViewModel.inactive))
            default:
                // TODO: Handle more cases
                break
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)

        exposureStateStreamCancellable = nil
    }

    // MARK: - Private
    
    private lazy var statusView: StatusView = StatusView()

}

fileprivate final class StatusView: View {

    fileprivate weak var listener: StatusListener?

    fileprivate let stretchGuide = UILayoutGuide() // grows larger while stretching, grows all visible elements
    fileprivate let contentStretchGuide = UILayoutGuide() // grows larger while stretching, used to center the content

    fileprivate let contentContainer = UIStackView()
    fileprivate let textContainer = UIStackView()
    fileprivate let buttonContainer = UIStackView()
    fileprivate let cardView = StatusCardView()

    fileprivate let iconView = StatusIconView()

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

        cloudsImageView.image = UIImage(named: "StatusClouds")
        addSubview(cloudsImageView)

        sceneImageView.contentMode = .scaleAspectFit
        sceneImageView.image = UIImage(named: "StatusScene")
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
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        textContainer.addArrangedSubview(titleLabel)
        //   descriptionLabel
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
        self.heightConstraint = heightAnchor.constraint(equalToConstant: 0).withPriority(.defaultHigh+100)

        let sceneImageAspectRatio = sceneImageView.image.map { $0.size.width / $0.size.height } ?? 1

        NSLayoutConstraint.activate([
            cloudsImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            cloudsImageView.leadingAnchor.constraint(equalTo: stretchGuide.leadingAnchor),
            cloudsImageView.trailingAnchor.constraint(equalTo: stretchGuide.trailingAnchor),

            sceneImageView.leadingAnchor.constraint(equalTo: stretchGuide.leadingAnchor),
            sceneImageView.trailingAnchor.constraint(equalTo: stretchGuide.trailingAnchor),
            sceneImageView.bottomAnchor.constraint(equalTo: stretchGuide.bottomAnchor),
            sceneImageView.widthAnchor.constraint(equalTo: sceneImageView.heightAnchor, multiplier: sceneImageAspectRatio),

            stretchGuide.leadingAnchor.constraint(equalTo: contentStretchGuide.leadingAnchor, constant: -16),
            stretchGuide.trailingAnchor.constraint(equalTo: contentStretchGuide.trailingAnchor, constant: 16),
            stretchGuide.topAnchor.constraint(equalTo: contentStretchGuide.topAnchor, constant: -70),
            stretchGuide.bottomAnchor.constraint(greaterThanOrEqualTo: contentStretchGuide.bottomAnchor),

            contentStretchGuide.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            contentStretchGuide.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            contentStretchGuide.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            contentStretchGuide.heightAnchor.constraint(greaterThanOrEqualTo: contentContainer.heightAnchor),

            stretchGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            stretchGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
            stretchGuide.topAnchor.constraint(equalTo: topAnchor).withPriority(.defaultLow),
            stretchGuide.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let widthChanged = gradientLayer.frame.width != bounds.width

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = stretchGuide.layoutFrame
        CATransaction.commit()

        if widthChanged {
            evaluateHeight()
        }
    }

    func update(with viewModel: StatusViewModel) {
        iconView.update(with: viewModel.icon)

        titleLabel.attributedText = viewModel.title
        descriptionLabel.attributedText = viewModel.description

        buttonContainer.subviews.forEach { $0.removeFromSuperview() }
        for buttonModel in viewModel.buttons {
            let button = Button(title: buttonModel.title)
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

        gradientLayer.colors = [viewModel.gradientColor.cgColor, UIColor.white.withAlphaComponent(0).cgColor]

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

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

    private var exposureStateStreamCancellable: AnyCancellable?

    init(exposureStateStream: ExposureStateStreaming, listener: StatusListener) {
        self.exposureStateStream = exposureStateStream
        self.listener = listener

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        self.view = statusView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // TODO: remove
        statusView.update(with: .active)
        exposureStateStreamCancellable = exposureStateStream.exposureStatus.sink { [weak self] status in
            switch (status) {
            case .active:
                self?.statusView.update(with: .active)
            case .notified:
                self?.statusView.update(with: .notified)
            default:
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

    fileprivate let container = UIStackView()
    fileprivate let textContainer = UIStackView()
    fileprivate let buttonContainer = UIStackView()

    fileprivate let iconView = StatusIconView()

    fileprivate let titleLabel = Label()
    fileprivate let descriptionLabel = Label()

    fileprivate let gradientLayer = CAGradientLayer()
    fileprivate let cloudsImageView = UIImageView()
    fileprivate let sceneImageView = UIImageView()

    fileprivate var containerToSceneVerticalConstraint: NSLayoutConstraint?

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
        container.axis = .vertical
        container.spacing = 24
        container.alignment = .center

        // iconView
        container.addArrangedSubview(iconView)

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

        container.addArrangedSubview(textContainer)

        // buttonContainer
        buttonContainer.axis = .vertical
        buttonContainer.spacing = 16
        container.addArrangedSubview(buttonContainer)

        addSubview(container)
    }
    
    override func setupConstraints() {
        super.setupConstraints()

        cloudsImageView.translatesAutoresizingMaskIntoConstraints = false
        sceneImageView.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        containerToSceneVerticalConstraint = sceneImageView.topAnchor.constraint(greaterThanOrEqualTo: container.bottomAnchor)

        let sceneImageAspectRatio = sceneImageView.image.map { $0.size.width / $0.size.height } ?? 1

        NSLayoutConstraint.activate([
            cloudsImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            cloudsImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cloudsImageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            sceneImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sceneImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sceneImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sceneImageView.widthAnchor.constraint(equalTo: sceneImageView.heightAnchor, multiplier: sceneImageAspectRatio),

            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: -20),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 20),
            topAnchor.constraint(equalTo: container.topAnchor, constant: -70),
            bottomAnchor.constraint(greaterThanOrEqualTo: container.bottomAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor).withPriority(.defaultLow),

            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
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

        gradientLayer.colors = [viewModel.gradientColor.cgColor, UIColor.white.withAlphaComponent(0).cgColor]

        sceneImageView.isHidden = !viewModel.showScene
        containerToSceneVerticalConstraint?.isActive = viewModel.showScene
    }
}

/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// @mockable
protocol StatusRouting: Routing {
}

final class StatusViewController: ViewController, StatusViewControllable {
    
    // MARK: - StatusViewControllable

    weak var router: StatusRouting?
    private weak var listener: StatusListener?

    init(listener: StatusListener) {
        self.listener = listener

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with viewModel: StatusViewModel) {
        statusView.update(with: viewModel)
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        self.view = statusView
    }
    
    // MARK: - Private
    
    private lazy var statusView: StatusView = StatusView()

}

fileprivate final class StatusView: View {

    fileprivate weak var listener: StatusListener?

    fileprivate let container = UIStackView()
    fileprivate let textContainer = UIStackView()
    fileprivate let buttonContainer = UIStackView()

    fileprivate let iconView = UIImageView()

    fileprivate let titleLabel = Label()
    fileprivate let descriptionLabel = Label()

    override func build() {
        super.build()

        // container
        container.axis = .vertical
        container.spacing = 24
        container.alignment = .center

        // iconView
        iconView.contentMode = .center
        iconView.layer.cornerRadius = 24
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
        
        container.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: -20),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 20),
            topAnchor.constraint(equalTo: container.topAnchor, constant: -70),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    func update(with viewModel: StatusViewModel) {
        iconView.backgroundColor = viewModel.icon.color
        iconView.image = viewModel.icon.icon

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
    }
}

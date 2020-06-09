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
    
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController,
                animated: animated,
                completion: completion)
    }
    
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        viewController.uiviewController.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        self.view = statusView
    }
    
    // MARK: - Private
    
    private lazy var statusView: StatusView = StatusView()

}

fileprivate final class StatusView: View {
    fileprivate let iconView = UIImageView()
    fileprivate let titleLabel = Label()
    fileprivate let descriptionLabel = Label()
    
    override func build() {
        super.build()
        
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        
        titleLabel.textAlignment = .center
        descriptionLabel.textAlignment = .center
        
        titleLabel.text = "De app is actief"
        
        descriptionLabel.text = "Je krijgt een melding nadat je extra kans op besmetting hebt opgelopen"
        descriptionLabel.numberOfLines = 0
        
        backgroundColor = .orange
        iconView.backgroundColor = .green
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 44),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 88),
            iconView.heightAnchor.constraint(equalToConstant: 88),
            
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 44),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: safeAreaInsets.left),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -safeAreaInsets.right),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 44),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -44),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: safeAreaInsets.left),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -safeAreaInsets.right),
            
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}

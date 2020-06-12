/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// @mockable
protocol StatusViewControllable: ViewControllable {
    var router: StatusRouting? { get set }

    func update(with viewModel: StatusViewModel)
}

final class StatusRouter: Router<StatusViewControllable>, StatusRouting {
    
    // MARK: - Initialisation
    
    init(listener: StatusListener,
         viewController: StatusViewControllable) {
        self.listener = listener
        // self.childBuilder = childBuilder
        
        super.init(viewController: viewController)
        
        viewController.router = self
    }

    func update(with viewModel: StatusViewModel) {
        self.viewController.update(with: viewModel)
    }
    
    // MARK: - Private
    
    // TODO: Add any private functions and instance variables here
    
    private weak var listener: StatusListener?
    
    // private let childBuilder: ChildBuildable
    // private var childViewController: ViewControllable?
}

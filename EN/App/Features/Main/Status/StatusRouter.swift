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
    
    // TODO: Add any child routing functions here.
    //       See RootRouter as an example
    //
    //    func routeToChild() {
    //        guard childViewController == nil else {
    //            // already presented
    //            return
    //        }
    //
    //        let childViewController = self.childBuilder.build()
    //        self.childViewController = childViewController
    //
    //        self.viewController.present(viewController: childViewController,
    //                                    animated: true,
    //                                    completion: nil)
    //    }
    //
    //    func detachChild() {
    //        guard let childViewController = childViewController else {
    //            return
    //        }
    //
    //        self.childViewController = nil
    //
    //        viewController.dismiss(viewController: childViewController,
    //                               animated: animated,
    //                               completion: completion)
    //    }
    
    // MARK: - Private
    
    // TODO: Add any private functions and instance variables here
    
    private weak var listener: StatusListener?
    
    // private let childBuilder: ChildBuildable
    // private var childViewController: ViewControllable?
}

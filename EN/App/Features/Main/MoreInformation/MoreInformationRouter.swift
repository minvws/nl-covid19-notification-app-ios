/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// @mockable
protocol MoreInformationViewControllable: ViewControllable {
    var router: MoreInformationRouting? { get set }

    // TODO: Validate whether you need the below functions and remove or replace
    //       them as desired.
    
    /// Presents a viewController
    ///
    /// - Parameter viewController: ViewController to present
    /// - Parameter animated: Animates the transition
    /// - Parameter completion: Executed upon presentation completion
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
    
    /// Dismisses a viewController
    ///
    /// - Parameter viewController: ViewController to dismiss
    /// - Parameter animated: Animates the transition
    /// - Parameter completion: Executed upon presentation completion
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
}

final class MoreInformationRouter: Router<MoreInformationViewControllable>, MoreInformationRouting {
    
    // MARK: - Initialisation
    
    init(listener: MoreInformationListener,
         viewController: MoreInformationViewControllable) {
        self.listener = listener
        
        super.init(viewController: viewController)
        
        viewController.router = self
    }
    
    // MARK: - Private
    
    private weak var listener: MoreInformationListener?
}

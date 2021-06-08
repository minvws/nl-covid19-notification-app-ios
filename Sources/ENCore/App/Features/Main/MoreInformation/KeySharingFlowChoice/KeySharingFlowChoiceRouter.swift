/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol KeySharingFlowChoiceViewControllable: ViewControllable {
    var router: KeySharingFlowChoiceRouting? { get set }

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
//    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?)
}

final class KeySharingFlowChoiceRouter: Router<KeySharingFlowChoiceViewControllable>, KeySharingFlowChoiceRouting, InfectedListener {
    
    // MARK: - Initialisation

    init(listener: KeySharingFlowChoiceListener,
         viewController: KeySharingFlowChoiceViewControllable,
         infectedBuilder: InfectedBuildable) {
        self.listener = listener
        self.infectedBuilder = infectedBuilder

        super.init(viewController: viewController)

        viewController.router = self
    }
    
    // MARK: - KeySharingFlowChoiceRouting
    
    func routeToShareKeyViaGGD() {
        guard infectedRouter == nil else {
            // already presented
            return
        }
        
        let router = self.infectedBuilder.build(withListener: self)
        self.infectedRouter = router
        
        self.viewController.present(viewController: router.viewControllable,
                                    animated: true,
                                    completion: nil)
    }
    
    func routeToShareKeyViaWebsite() {
        //TODO: Route to key sharing via website
    }
    
    func keySharingFlowChoiceWantsDismissal(shouldDismissViewController: Bool) {
        listener?.KeySharingFlowChoiceWantsDismissal(shouldDismissViewController: shouldDismissViewController)
    }
    
    // MARK: - InfectedListener
    
    func infectedWantsDismissal(shouldDismissViewController: Bool) {
        listener?.KeySharingFlowChoiceWantsDismissal(shouldDismissViewController: shouldDismissViewController)
    }
    
    // MARK: - Private

    private weak var listener: KeySharingFlowChoiceListener?
    private let infectedBuilder: InfectedBuildable
    private var infectedRouter: Routing?
}

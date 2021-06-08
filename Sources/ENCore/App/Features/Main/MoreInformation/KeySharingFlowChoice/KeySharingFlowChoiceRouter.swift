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
    func presentInNavigationController(viewController: ViewControllable)
    func dismiss(viewController: ViewControllable)
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
        infectedRouter = router
        
        viewController.presentInNavigationController(viewController: router.viewControllable)
    }
    
    func routeToShareKeyViaWebsite() {
        //TODO: Route to key sharing via website
    }
    
    func keySharingFlowChoiceWantsDismissal(shouldDismissViewController: Bool) {
        listener?.keySharingFlowChoiceWantsDismissal(shouldDismissViewController: shouldDismissViewController)
    }
    
    // MARK: - InfectedListener
    
    func infectedWantsDismissal(shouldDismissViewController: Bool) {
        guard let infectedRouter = infectedRouter, shouldDismissViewController else {
            return
        }
        
        viewController.dismiss(viewController: infectedRouter.viewControllable)
    }
    
    // MARK: - Private

    private weak var listener: KeySharingFlowChoiceListener?
    private let infectedBuilder: InfectedBuildable
    private var infectedRouter: Routing?
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol DashboardDetailViewControllable: ViewControllable {
    var router: DashboardDetailRouting? { get set }
}

final class DashboardDetailRouter: Router<DashboardDetailViewControllable>, DashboardDetailRouting {

    // MARK: - Initialisation

    init(listener: DashboardDetailListener,
         viewController: DashboardDetailViewControllable /* ,
          childBuilder: ChildBuildable */ ) {
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

    private weak var listener: DashboardDetailListener?

    // private let childBuilder: ChildBuildable
    // private var childViewController: ViewControllable?
}

/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
protocol ___VARIABLE_componentName___ViewControllable: ViewControllable {
    var router: ___VARIABLE_componentName___Routing? { get set }

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

final class ___VARIABLE_componentName___Router: Router<___VARIABLE_componentName___ViewControllable>, ___VARIABLE_componentName___Routing {

    // MARK: - Initialisation

    init(listener: ___VARIABLE_componentName___Listener,
         viewController: ___VARIABLE_componentName___ViewControllable /* ,
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

    private weak var listener: ___VARIABLE_componentName___Listener?

    // private let childBuilder: ChildBuildable
    // private var childViewController: ViewControllable?
}

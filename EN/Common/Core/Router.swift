/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol Routing: AnyObject {
    var viewControllable: ViewControllable { get }
}

/// Routers control the child viewController stack of
/// the associated ViewController object
///
/// Note: All ViewController types used in Router should conform to ViewControllable
class Router<ViewController>: Routing {
    let viewControllable: ViewControllable
    let viewController: ViewController
    
    init(viewController: ViewController) {
        guard let viewControllable = viewController as? ViewControllable else {
            fatalError("All viewControllers used in Routers should conform to ViewControllable")
        }
        
        self.viewController = viewController
        self.viewControllable = viewControllable
    }
}
